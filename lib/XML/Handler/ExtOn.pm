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
    if ( my $current_element = $self->current_element ) {
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
    return $elem->to_sax2;
}

sub on_start_element {
    shift;
    return @_;
}

sub characters {
    my $self = shift;
    my ($data) = @_;
    return if $self->current_element->skip_content;

#    warn Dumper ({'$data'=>$data, 'current'=>$self->_objects_stack()->[-1]->local_name});
    return $self->SUPER::characters(@_);
}

sub current_element {
    my $self = shift;
    $self->_objects_stack()->[-1];
}

sub start_element {
    my $self = shift;
    my $data = shift;
    return $self->SUPER::start_element($data)
      unless $self->can('on_start_element');

    #check current element for skip_content
    if ( my $current_element = $self->current_element ) {
        my $skip_content = $current_element->skip_content;

#        warn "Start: ". $current_element->name." skip: $skip_content".Dumper($data);
        if ($skip_content) {
            $current_element->skip_content( ++$skip_content );

            #            warn "skip on start" . Dumper($data);
            return;
        }
    }
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

    #    return if $res_element->skip_content;
    return $self->SUPER::start_element($res_data);
}

sub on_end_element {
    shift;
    return @_;
}

sub end_element {
    my $self = shift;
    my $data = shift;

    #check current element for skip_content
    if ( my $current_element = $self->current_element ) {
        my $skip_content = $current_element->skip_content;

#        warn "End: ". $current_element->name." skip: $skip_content".Dumper($data);
        if ($skip_content) {
            $current_element->skip_content( --$skip_content );

            #            warn "skip " . Dumper($data) if $skip_content == 1;
            return if $skip_content == 1;

        }
    }

    #    warn Dumper($data);
    #save element in stack
    my $current_obj = pop @{ $self->_objects_stack() };

    #setup default ns
    $data = $current_obj->to_sax2;
    delete $data->{Attributes};
    $data->{NamespaceURI} = $current_obj->default_uri;

    $self->on_end_element( $current_obj, $data );

    $self->SUPER::end_element($data);
    my $changes    = $current_obj->ns->get_changes;
    my $parent_map = $current_obj->ns->parent->get_map;
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
