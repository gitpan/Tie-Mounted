package Tie::Mounted;

$VERSION = '0.02';

use strict 'vars';
use vars qw(
    $MOUNT_BIN 
    $UMOUNT_BIN
    $Only
);
use base qw(Tie::Array);
use Carp qw(carp croak);

$MOUNT_BIN  = '/sbin/mount';
$UMOUNT_BIN = '/sbin/umount';

sub _private {
    my $APPROVE = 1;
    my @NODES   = qw( );
    
 
    return _localcall(1,56,57) 
      ? eval do { $_[0] } : '';     
}

sub TIEARRAY {
    my $class = shift;
    return bless &_tie, $class;
}

sub FETCHSIZE { (scalar @{$_[0]} - 1) }

sub FETCH { 
    my($self, $i) = @_;
    return $self->[++$i];
}

*STORESIZE = \&_carp;
*STORE     = \&_carp;

sub UNTIE { &_approve('umount', $_[0]->[0]) }

sub _tie {
    my $node = pop;
    _approve('mount', $node, grep !/^-(?:a|A|d)$/, @_);
    my $items = []; $items = _read_dir($node) if !$Only;
    # Store node at index 0
    unshift @$items, $node;    
    return $items;
}

sub _approve {
    my $sub = shift;
    my $approved;
    croak 'No valid node supplied' if !-d $_[0];
    if (_private('$APPROVE')) { 
        $approved = grep { $_[0] eq $_ } _private('@NODES');
	croak "Attempt to $sub unapproved node" if $approved == 0; 
    }
    &{"_$sub"};
}
  
sub _mount {
    die '_mount is private' unless _localcall(1,60);
    my $node = shift;
    unless(_is_mounted($node)) {
        my $cmd = "$MOUNT_BIN @_ $node";
        system($cmd) == 0 or die "$cmd: $!";
    }
}

sub _is_mounted {
    my $node = shift;
    open PIPE, "$MOUNT_BIN |" 
      or die "Couldn't init pipe to $MOUNT_BIN: $!";
    for (<PIPE>) { return 1 if /$node/ }
    close PIPE 
      or die "Couldn't drop pipe to $MOUNT_BIN: $!";
    return 0;
}

sub _read_dir {
    my $node = shift;
    local *D;
    opendir D, $node
      or die "Couldn't init access to $node: $!";
    my @items = sort readdir D; splice(@items, 0, 2);
    closedir D or die "Couldn't drop access to $node: $!";
    return \@items;
}

sub _umount {
    die '_umount is private' unless _localcall(1,60);
    my $node = shift;
    my $cmd = "$UMOUNT_BIN $node";
    system($cmd) == 0 or die "\n$cmd: $!";
}

sub _localcall {
    my @called = caller(shift);
    return 0 if $called[0] ne __PACKAGE__;
    for (@_) { return 1 if $called[2] == $_ }
    return 0;
}

sub _carp { carp 'Tied array is read-only' }

1;
__END__

=head1 NAME

Tie::Mounted - Tie a mounted node to an array

=head1 SYNOPSIS

 require Tie::Mounted;

 tie @items, 'Tie::Mounted', '-v', '/backup';
 print $items[-1];
 untie @items;

=head1 DESCRIPTION

This module ties files of a mount point to an array by invoking
the system commands C<mount> and C<umount>; C<mount> is invoked
when a former attempt to tie an array is being committed,
C<umount> when a tied array is to be untied.

The mandatory parameter consists of the node (or: I<mount point>)
to be mounted (F</backup> - as declared in F</etc/fstab>); 
optional options to C<mount> may be preceedingly passed (-v).
Device names and mount options (-a,-A,-d) will be discarded
in regard of system security.

If $Tie::Mounted::Only is set to a true value, a bogus array with
zero files will be tied.

=head1 CAVEATS

=head2 Security

Tie::Mounted requires by default to either have $APPROVE
set to an untrue value in order to pass nodes as desired, or 
@NODES to contain the nodes that are considered ``approved";
both variables are lexically scoped and adjustable within _private(). 
If in approval mode and a node is passed that is considered
unapproved, Tie::Mounted will throw an exception.

Such ``security" is rather trivial; instead it is recommended 
to adjust the filesystem permissions of the module file to prevent 
malicious use.

=head2 Portability

It is doubted that it will work not reliably on a non-(Open)BSD 
system due to the fact that a pipe to mount has to be established to 
ensure that a node is not already being mounted; which in return
requires a parameter to be passed to mount which widely varies 
on BSD systems.

=head2 Miscellanea

The tied array may not be altered by C<shift>, C<unshift>, C<pop>, 
C<push>, C<splice> or any other functions that are known to have a 
sufficient ``impact" on contents of lists.

Files within the tied array are statically tied.

=head2 Internals

Do not modify guts unless you adjust the parameters
of _localcall().

=head1 SEE ALSO

L<perlfunc/tie>, fstab(5), mount(8), umount(8)

=cut
