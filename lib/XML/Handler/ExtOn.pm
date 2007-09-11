package XML::Handler::ExtOn;
use strict;
use warnings;

use Carp;
use Data::Dumper;

#use XML::NamespaceSupport;
use XML::SAX::Base;
use XML::Handler::ExtOn::Element;
use XML::Handler::ExtOn::Context;
use base 'XML::SAX::Base';
use vars qw( $AUTOLOAD);
### install get/set accessors for this object.
for my $key (qw/ context _objects_stack/) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{___EXT_on_attrs}->{$key} = $_[0] if @_;
        return $self->{___EXT_on_attrs}->{$key};
      }
}

sub start_document {
    my ( $self, $document ) = @_;
    my $doc_context = new XML::Handler::ExtOn::Context::;
    $self->context($doc_context);
    $self->_objects_stack( [] );
    $self->SUPER::start_document($document);
}

sub mk_element {
    my $self = shift;
    my $name = shift;
    my %args = @_;
    if ( my $current_element = @{ $self->_objects_stack() }[-1]) {
        $args{context} = $current_element->ns->sub_context();
    }
    $args{context} ||= $self->context->sub_context();
    my $elem = new XML::Handler::ExtOn::Element::
      name => $name,
      %args;
    return $elem;
}

sub __mk_element_from_sax2 {
    my $self = shift;
    my $data = shift;
    my $elem = $self->mk_element( $data->{LocalName}, sax2 => $data, @_ );
    return $elem;
}

sub __exp_element_to_sax2 {
    my $self = shift;
    my $elem = shift;
    my $data = {
        Prefix     => $elem->set_prefix,
        LocalName  => $elem->local_name,
        Attributes => $elem->attrs_to_sax2,
        Name       => $elem->set_prefix
        ? $elem->set_prefix() . ":" . $elem->name
        : $elem->name,
        NamespaceURI => $elem->set_prefix ? $elem->set_ns_uri() : '',
};
    return $data;
}

sub start_element {
    my $self = shift;
    my $data = shift;
    warn "Start ElementSAX:" . Dumper($data);
    return $self->SUPER::start_element($data)
      unless $self->can('on_start_element');
    my $elem        = $self->__mk_element_from_sax2($data);
    my $res_element = $self->on_start_element($elem);
    my $res_data    = $self->__exp_element_to_sax2($res_element);

    #register new namespaces
    my $changes    = $res_element->ns->get_changes;
    my $parent_map = $res_element->ns->parent->get_map;

    #warn Dumper( { changes => $changes } );
    for ( keys %$changes ) {
        $self->SUPER::end_prefix_mapping(
            {
                Prefix       => $_,
                NamespaceURI => $parent_map->{$_},
            }
          )
          if exists $parent_map->{$_};
        $self->SUPER::start_prefix_mapping(
            {
                Prefix       => $_,
                NamespaceURI => $changes->{$_},
            }
        );
    }

    #save element in stack
    push @{ $self->_objects_stack() }, $res_element;

    #    warn "Start ElementAfter:".Dumper($res_data);
    warn "Start Element _attr:" . Dumper( $res_element->{__attrs} );
    return $self->SUPER::start_element($res_data);
}

sub on_end_element {
    shift;
    return @_;
}

sub end_element {
    my $self = shift;
    my $data = shift;

    #save element in stack
    my $current_obj = pop @{ $self->_objects_stack() };
    my $changes     = $current_obj->ns->get_changes;
    my $parent_map  = $current_obj->ns->parent->get_map;
    $self->on_end_element( $data, $current_obj );
    $self->SUPER::end_element($data);
    for ( keys %$changes ) {
        $self->SUPER::end_prefix_mapping(
            {
                Prefix       => $_,
                NamespaceURI => $changes->{$_},
            }
        );
        if ( exists( $parent_map->{$_} ) ) {
            $self->SUPER::start_prefix_mapping(
                {
                    Prefix       => $_,
                    NamespaceURI => $parent_map->{$_},
                }
            );
        }
    }
}

sub AUTOLOAD {
    my $self = shift;
    my $data = shift;
    my $call = $AUTOLOAD;
    $call =~ s/^.*:://;
    return if $call eq 'DESTROY';

    #    warn Dumper($data);
    $call = "SUPER::$call";
    return $self->$call($data);
}
1;
