package MooseX::NewDefaults;

# ABSTRACT: Alter attribute defaults with less pain

use Moose 0.94 ();
use namespace::autoclean;
use Moose::Exporter;
use Moose::Util;

sub default_for {
    my ($meta, $attribute_name, $new_default) = (shift, shift, shift);

    # yes, Moose::Role will explode letting the caller know that roles don't
    # currently support attribute extension... but that's M::R's problem, not
    # ours :)

    my $sub
       = $meta->isa('Moose::Meta::Role')
       ? \&Moose::Role::has
       : \&Moose::has
       ;

    # massage into what has() expects
    @_ = ($meta, "+$attribute_name", default => $new_default);
    goto \&$sub;
    return;
}

Moose::Exporter->setup_import_methods(with_meta => [ qw{ default_for } ]);

!!42;

__END__

=head1 SYNOPSIS

    package One;
    use Moose;
    use namespace::autoclean;

    has A => (is => 'ro', default => sub { 'say ahhh' });
    has B => (is => 'ro', default => sub { 'say whoo' });

    package Two;
    use Moose;
    use namespace::autoclean;
    use MooseX::NewDefaults;

    extends 'One';

    # sugar for defining a new default
    default_for A => sub { 'say oooh' };

    # this is also legal
    default_for B => 'say oooh';

=head1 DESCRIPTION

Ever start using a package from the CPAN, only to discover that it requires
lots of subclassing and "has '+foo' => (default => ...)"?  It's not
recommended Moose best practice, and it's certainly not the prettiest thing
ever, either.

That's where we come in.

This package introduces new sugar that you can use in your class,
default_for (as seen above).

e.g.

    has '+foo' => (default => sub { 'a b c' });

...is the same as:

    default_for foo => sub { 'a b c' };

=head1 NEW SUGAR

=head2 default_for

default_for() is a shortcut to extend an attribute to give it a new default;
this default value may be any legal value for default options.

    # attribute bar defined elsewhere (e.g. superclass)
    default_for bar => 'new default';

... is the same as:

    has '+bar' => (default => 'new default');

=head1 BUGS

All complex software has bugs lurking in it, and this module is no exception.

Bugs, feature requests and pull requests through GitHub are most welcome; our
page and repository (same URI):

    https://github.com/RsrchBoy/moosex-newdefaults

=cut
