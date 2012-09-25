package MooseX::NewDefaults::Magic;

# ABSTRACT: A slightly more magical version of NewDefaults

use Moose 0.94 ();
use namespace::autoclean;
use Moose::Exporter;
use Moose::Util;

use MooseX::NewDefaults ();

{
    package MooseX::NewDefaults::Trait::Class;
    use Moose::Role;
    use namespace::autoclean;

    sub new_default_for_attribute {
        my ($self, $attribute_name, %options) = @_;

        ### find our attribute...
        my $att = $self->find_attribute_by_name($attribute_name);
        Moose->throw_error("Cannot find an attribute by the name of $attribute_name")
            unless $att;

        unless (scalar keys %options) {

            ### find our method and pull it...
            my $method = $self->get_method($attribute_name)
                || Moose->throw_error("Cannot find locally defined method named: $attribute_name");

            $options{default} = $method->body;
            $options{definition_context} = Moose::Util::_caller_info();

            require B;
            my $cv = B::svref_2object($options{default});

            $options{definition_context} = {
                package => $method->package_name,
                file    => $cv->GV->LINE, # $method->file,
                line    => $cv->FILE,     #'unknown',
            };

            ### and remove the method...
            $self->remove_method($attribute_name);
        }

        ### clone and extend the attribute with the new default...
        $self->add_attribute("+$attribute_name", %options);

        ### tada!

        return;
    }

    before make_immutable => sub {
        my $self = shift @_;

        # check for local methods named the same as an attribute that are not
        # accessors

        for my $name ($self->get_method_list) {

            my $method = $self->get_method($name);

            # skip if we're an accessor, or some other generated method
            #next if $method->isa('Class::MOP::Method::Generated');
            #next unless my $att = $self->find_attribute_by_name($name);

            $self->new_default_for_attribute($name)
                unless $method->isa('Class::MOP::Method::Generated')
                    || !$self->find_attribute_by_name($name)
                    ;
        }

        return;
    };

}

Moose::Exporter->setup_import_methods(
    also            => [ qw{ MooseX::NewDefaults } ],
    class_metaroles => {
        class => [ 'MooseX::NewDefaults::Trait::Class' ],
    },
);

!!42;

__END__

=head1 SYNOPSIS

    package One;
    use Moose;
    use namespace::autoclean;

    has B => (is => 'ro', default => sub { 'say whoo' });
    has C => (is => 'ro', default => sub { 'say bzzi' });

    package Two;
    use Moose;
    use namespace::autoclean;
    use MooseX::NewDefaults::Magic;
    extends 'One';

    # we include the default_for sugar
    default_for B => 'say oooh';

    # magic for defining a new default
    sub C { 'new default' }

    # necessary to invoke the magic
    __PACKAGE__->meta->make_immutable();

=head1 DESCRIPTION

This package applies a metaclass trait that, when the class is made immutable,
scans for any methods introduced in that class with the same name as an
attribute that exists at some point in the class' ancestry.  That method is
removed, and the attribute in question is extended to use the removed method
as its default.

e.g.

    # in some package
    has '+foo' => (default => sub { 'a b c' });

...is the same as:

    # in some package with newdefaults used
    sub foo { 'a b c' }
    __PACKAGE__->meta->make_immutable;

The default_for() sugar here is exactly the same as shown in
L<MooseX::NewDefaults>; please see there for more information.

=head1 NEW METACLASS METHODS

=head2 new_default_for_attribute($attribute_name, [ %options ])

Looks for an attribute called $attribute_name, then for a locally defined
method of the same name.  If found, removes the local method and uses it as
the new default for the attribute.

If called with any %options, it basically just works the same as
add_attribute("+$attribute_name" => %options).

=head1 SEE ALSO

L<MooseX::NewDefaults>

=cut
