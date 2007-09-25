package XML::Handler::ExtOn;

#$Id$
use strict;
use warnings;

use Carp;
use Data::Dumper;

use XML::SAX::Base;
use XML::Handler::ExtOn::Element;
use XML::Handler::ExtOn::Context;
use XML::Handler::ExtOn::IncXML;
use XML::Filter::SAX1toSAX2;
use XML::Parser::PerlSAX;

use base 'XML::SAX::Base';
use vars qw( $AUTOLOAD);
$XML::Handler::ExtOn::VERSION = '0.01'; 
### install get/set accessors for this object.
for my $key (qw/ context _objects_stack /) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{___EXT_on_attrs}->{$key} = $_[0] if @_;
        return $self->{___EXT_on_attrs}->{$key};
      }
}

sub new {
    my $class = shift;
    my $self = &XML::SAX::Base::new( $class, @_, );
    $self->_objects_stack( [] );
    my $doc_context = new XML::Handler::ExtOn::Context::;
    $self->context($doc_context);
    return $self;
}

sub on_start_document {
    my ( $self, $document ) = @_;
    $self->SUPER::start_document($document);
}

sub start_document {
    my ( $self, $document ) = @_;
    return if $self->{___EXT_on_attrs}->{_skip_start_docs}++;
    $self->on_start_document($document);
}

sub on_start_prefix_mapping {
    my $self = shift;
    my %map  = @_;
    while ( my ( $pref, $ns_uri ) = each %map ) {
        $self->SUPER::start_prefix_mapping({
            Prefix       => $pref,
            NamespaceURI => $ns_uri
        });
    }
}

=head2 start_prefix_mapping

#    { Prefix => 'xlink', NamespaceURI => 'http://www.w3.org/1999/xlink' }
=cut

sub start_prefix_mapping {
    my $self = shift;

    #declare namespace for current context
    my $context = $self->context;
    if ( my $current = $self->current_element ) {
        $context = $current->ns;
    }
    my %map = ();
    foreach my $ref (@_) {
        my ( $prefix, $ns_uri ) = @{$ref}{qw/Prefix NamespaceURI/};
        $context->declare_prefix( $prefix, $ns_uri );
        $map{$prefix} = $ns_uri;
    }
    # $self->SUPER::start_prefix_mapping(@_);
    $self->on_start_prefix_mapping(%map);
}

=head2 mk_element <tag name>

Return object of element item  for include to stream.


=cut

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

=head2 mk_from_xml <xml string>

Return command item  for include to stream

=cut

sub mk_from_xml {
    my $self          = shift;
    my $string        = shift;
    my $skip_tmp_root = XML::Handler::ExtOn::IncXML->new( Handler => $self );
    my $sax2_filter = XML::Filter::SAX1toSAX2->new( Handler => $skip_tmp_root );
    my $parser      = XML::Parser::PerlSAX->new(
        {
            Handler => $sax2_filter,
            Source  => { String => "<tmp>$string</tmp>" }
        }
    );
    return $parser;
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

=head2 on_start_element $elem

Method must return ref to array of mk_element, mk_from_xml, $elem .
$elem autoclose always.

=cut

sub on_start_element {
    shift;
    return [@_];
}

=head2 on_characters( $self->current_element, $data->{Data} )

return string for write 

=cut

sub on_characters {
    my ( $self, $elem, $str ) = @_;
    return $str;
}

sub characters {
    my $self = shift;
    my ($data) = @_;

#skip childs elements characters ( > 1 ) and self text ( > 0)
#    warn $self.Dumper([ map {[caller($_)]} (1..10)]) unless $self->current_element;
    if ( $self->current_element ) {
        return if $self->current_element->is_skip_content;
    }
    else {

        #skip characters without element
        return

          #        #warn "characters without element"
    }

    #collect chars fo current element
    if (
        defined(
            my $str =
              $self->on_characters( $self->current_element, $data->{Data} )
        )
       )
    {
        return $self->SUPER::characters( { Data => $str } );
    }
}

=head2 current_element 

Return link to current processing element 

=cut

sub current_element {
    my $self = shift;
    if ( my $stack = $self->_objects_stack() ) {
        return $stack->[-1];
    }
    return;
}

sub start_element {
    my $self = shift;
    my $data = shift;

    #check current element for skip_content
    if ( my $current_element = $self->current_element ) {
        my $skip_content = $current_element->is_skip_content;
        if ($skip_content) {
            $current_element->is_skip_content( ++$skip_content );
            return;
        }
    }
    my $current_obj =
      UNIVERSAL::isa( $data, 'XML::Handler::ExtOn::Element' )
      ? $data
      : $self->__mk_element_from_sax2($data);
    my $res   = $self->on_start_element($current_obj);
    my @stack = $res
      ? ref($res) eq 'ARRAY' ? @{$res} : ($res)
      : ();
    push @stack, $current_obj;
    my %uniq = ();

    #process answer
    foreach my $elem (@stack) {

        #clean dups
        next if $uniq{$elem}++;
        unless ( $elem eq $current_obj ) {

            #            warn $elem->local_name;
            $self->process_comm($elem);
        }
        else {

            my $res_data = $self->__exp_element_to_sax2($current_obj);

            #register new namespaces
            my $changes    = $current_obj->ns->get_changes;
            my $parent_map = $current_obj->ns->parent->get_map;

            #warn Dumper( { changes => $changes } );
            for ( keys %$changes ) {
#                $self->SUPER::end_prefix_mapping(
                $self->end_prefix_mapping(
                    {
                        Prefix       => $_,
                        NamespaceURI => $parent_map->{$_},
                    }
                  )
                  if exists $parent_map->{$_};
#                $self->SUPER::start_prefix_mapping(
                $self->start_prefix_mapping(
                    {
                        Prefix       => $_,
                        NamespaceURI => $changes->{$_},
                    }
                );
            }

            #save element in stack
            push @{ $self->_objects_stack() }, $current_obj;

            #skip deleted elements from xml stream
            $self->SUPER::start_element($res_data)
              unless $current_obj->is_delete_element;
            unless ( $current_obj->is_skip_content ) {
                $self->process_comm($_) for @{ $current_obj->_stack };
                $current_obj->_stack( [] );
            }
        }

    }
}

=head2 on_end_element $elem

Method must return ref to array of mk_element, mk_from_xml, $elem .
$elem autoclose always.

=cut

sub on_end_element {
    shift;
    return [@_];
}

sub end_document {
    my $self = shift;
    my $var  = --$self->{___EXT_on_attrs}->{_skip_start_docs};
    return if $var;
    $self->SUPER::end_document(@_);
}

=head2  process_comm <command>

process command

=cut

sub process_comm {
    my $self = shift;
    my $comm = shift || return;
    if ( UNIVERSAL::isa( $comm, 'XML::Parser::PerlSAX' ) ) {
        $comm->parse;
    }
    elsif ( UNIVERSAL::isa( $comm, 'XML::Handler::ExtOn::Element' ) ) {
        $self->start_element($comm);

        #        warn Dumper($comm->_stack, $comm->local_name);
        while ( my $obj = shift @{ $comm->_stack } ) {
            $self->process_comm($obj);
        }
        $self->end_element($comm);
    }
    else {
        warn " Unknown DATA $comm";
    }
}

sub end_element {
    my $self = shift;
    my $data = shift;

    #check current element for skip_content
    if ( my $current_element = $self->current_element ) {
        my $skip_content = $current_element->is_skip_content;
        if ( $skip_content > 1 ) {
            $current_element->is_skip_content( --$skip_content );
            return;
        }
    }

    #    warn Dumper($data);
    #pop element from stack
    my $current_obj = pop @{ $self->_objects_stack() };

    #setup default ns
    $data = $current_obj->to_sax2;
    delete $data->{Attributes};
    $data->{NamespaceURI} = $current_obj->default_uri;

    my $res   = $self->on_end_element($current_obj);
    my @stack = $res
      ? ref($res) eq 'ARRAY' ? @{$res} : ($res)
      : ();
    push @stack, $current_obj;
    my %uniq = ();

    #process answer
    foreach my $elem (@stack) {

        #clean dups
        next if $uniq{$elem}++;
        unless ( $elem eq $current_obj ) {
            $self->process_comm($elem);
        }
        else {
            unless ( $current_obj->is_skip_content ) {
                $self->process_comm($_) for @{ $current_obj->_stack };
                $current_obj->_stack( [] );
            }
            $self->SUPER::end_element($data)
              unless $current_obj->is_delete_element;
            my $changes    = $current_obj->ns->get_changes;
            my $parent_map = $current_obj->ns->parent->get_map;
            for ( keys %$changes ) {
#                $self->SUPER::end_prefix_mapping(
                $self->end_prefix_mapping(
                    {
                        Prefix       => $_,
                        NamespaceURI => $changes->{$_},
                    }
                );
                if ( exists( $parent_map->{$_} ) ) {
#                    $self->SUPER::start_prefix_mapping(
                    $self->start_prefix_mapping(
                        {
                            Prefix       => $_,
                            NamespaceURI => $parent_map->{$_},
                        }
                    );
                }
            }
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
    #    warn $call;
    $call = "SUPER::$call";
    return $self->$call($data);
}
1;
