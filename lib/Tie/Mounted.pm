package Tie::Mounted;

$VERSION = '0.09';

use strict 'vars';
use vars qw(
    $FSTAB
    $MOUNT_BIN 
    $UMOUNT_BIN
    $No_files
);
use base qw(Tie::Array);
use Carp 'croak';

$FSTAB      = '/etc/fstab';
$MOUNT_BIN  = '/sbin/mount';
$UMOUNT_BIN = '/sbin/umount';


sub _private {
    my $APPROVE = 1;
    my @NODES   = qw(    );
    
 
    return eval do { $_[0] };     
}

{
    sub TIEARRAY {
        my $class = shift;
	
	_validate_node($_[0]);
	
        return bless &_tie, $class;
    }

    # FETCHSIZE, FETCH: Due to the node, 
    # which is being kept hideously, accordingly 
    # subtract (FETCHSIZE) or add (FETCH) 1. 
    sub FETCHSIZE { $#{$_[0]} }
    sub FETCH     { $_[0]->[++$_[1]] }

    *STORESIZE = *STORE = 
      sub { croak 'Tied array is read-only' };

    sub UNTIE { _approve('umount', $_[0]->[0]) }
}

sub _validate_node {
    my($node) = @_;
    
    local (*F_TABS, $/); 
    $/ = '';
    
    open F_TABS, "<$FSTAB" or die "Couldn't open $FSTAB: $!";
    my $fstabs = <F_TABS>;
    close F_TABS or die "Couldn't close $FSTAB: $!";
    
    !$node
      ? croak 'No node supplied'
      : !-d $node
        ? croak "$node doesn't exist"
        : $fstabs =~ /^#.*$node/m
          ? croak "$node is enlisted as disabled in $FSTAB"
	  : $fstabs !~ /$node/s
	    ? croak "$node is not enlisted in $FSTAB"
	    : '';
}

sub _tie {
    my $node = shift;
    
    _approve('mount', $node, grep !/^-(?: a|A|d)$/ox, @_);
    
    my $items = $No_files
      ? []
      : _read_dir($node); 
    
    # Invisible node at index 0
    unshift @$items, $node;
        
    return $items;
}

sub _approve {
    my($sub, $node) = (shift, @_);
    
    if (_private('$APPROVE')) { 
	croak "Attempt to $sub unapproved node" 
	  unless (grep { $node eq $_ } _private('@NODES')); 
    }
    
    &{"_$sub"};
}
      
sub _mount {
    die '_mount is private' unless _localcall(1,93);
    
    my $node = shift;
    
    unless (_is_mounted($node)) {
        my $cmd = "$MOUNT_BIN @_ $node";
        system($cmd) == 0 or exit 1;
    }
}

sub _is_mounted {
    my($node) = @_;
    
    open PIPE, "$MOUNT_BIN |" 
      or die "Couldn't init pipe to $MOUNT_BIN: $!";
    my $ret = (grep /$node/, <PIPE>) ? 1 : 0;
    close PIPE 
      or die "Couldn't drop pipe to $MOUNT_BIN: $!";
      
    return $ret;
}

sub _read_dir {
    my($node) = @_;
    
    local *DIR;
    
    opendir DIR, $node
      or die "Couldn't init access to $node: $!";
    my @items = sort readdir DIR; splice(@items, 0, 2);
    closedir DIR or die "Couldn't drop access to $node: $!";
    
    return \@items;
}

sub _umount {
    die '_umount is private' unless _localcall(1,93);
    
    my($node) = @_;
    
    my $cmd = "$UMOUNT_BIN $node";
    system($cmd) == 0 or exit 1;
}

sub _localcall {
    my @called = (caller(shift))[0,2];
    
    return $called[0] ne __PACKAGE__ 
      ? 0
      : (grep { $called[1] == $_ } @_)
        ? 1 : 0;
}

1;
__END__

=head1 NAME

Tie::Mounted - Tie a mounted node to an array

=head1 SYNOPSIS

 require Tie::Mounted;

 tie @files, 'Tie::Mounted', '/backup', '-v';
 print $files[-1];
 untie @files;

=head1 DESCRIPTION

This module ties files (and directories) of a mount point to an 
array by invoking the system commands C<mount> and C<umount>; 
C<mount> is invoked when a former attempt to tie an array is 
being committed, C<umount> when a tied array is to be untied. 
Suitability is therefore limited and suggests a rarely 
used node (such as F</backup>).

The mandatory parameter consists of the node (or: I<mount point>)
to be mounted (F</backup> - as declared in F</etc/fstab>); 
optional options to C<mount> may be subsequently passed (-v).
Device names and mount options (-a,-A,-d) will be discarded
in regard of system security.

Default paths to C<mount> and C<umount> may be overriden
by setting accordingly either $Tie::Mounted::MOUNT_BIN or 
$Tie::Mounted::UMOUNT_BIN.

If $Tie::Mounted::No_files is set to a true value, 
a bogus array with zero files will be tied.

=head1 CAVEATS

=head2 Security

Tie::Mounted requires by default to either have $APPROVE
set to an untrue value in order to pass nodes as desired, or 
@NODES to contain the nodes that are considered ``approved";
both variables are lexically scoped and adjustable within _private(). 
If in approval mode and a node is passed that is considered
unapproved, Tie::Mounted will throw an exception.

Such ``security" is rather trivial; instead it is recommended 
to adjust filesystem permissions to prevent malicious use.

=head2 Portability

It is doubted that it will work reliably on a non-(Open)BSD 
system due to the fact that a pipe to mount has to be established to 
ensure that a node is not already being mounted; which requires a 
parameter to be passed that widely varies on common Unix systems.

=head2 Miscellanea

The tied array is read-only.

Files within the tied array are statically tied.

=head2 Internals

It is not recommended to modify internals unless the parameters
to _localcall() are being adjusted accordingly.

=head1 SEE ALSO

L<perlfunc/tie>, fstab(5), mount(8), umount(8)

=cut
