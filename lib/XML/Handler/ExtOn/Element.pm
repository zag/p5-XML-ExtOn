package XML::Handler::ExtOn::Element;
use strict;
use warnings;

use XML::NamespaceSupport;
use Carp;
use Data::Dumper;
use XML::Handler::ExtOn::TieAttrs;
use XML::Handler::ExtOn::Attributes;
for my $key (qw/ _context attributes _skip_content _delete_element/) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}

=head2 new name=>< element name>, context=>< context >[, sax2=><ref to sax2 structure>]

Create Element object

  my $element = new XML::Handler::ExtOn::Element::
      name    => "p",
      context => $context,
      [sax2 => $t1_elemnt ];

=cut

sub new {
    my ( $class, %attr ) = @_;
    my $self = bless {}, $class;
    $self->_context( $attr{context} ) or die "not exists context parametr";
    my $name = $attr{name};
    $self->attributes(
        new XML::Handler::ExtOn::Attributes::
          context => $self->_context,
        sax2 => exists $attr{sax2} ? $attr{sax2}->{Attributes} : {}
    );

    if ( my $sax2 = $attr{sax2} ) {
        $name ||= $sax2->{Name};
        $self->set_prefix( $sax2->{Prefix} || '' );
        $self->set_ns_uri( $self->ns->get_uri( $self->set_prefix() ) );
    }
    $self->_set_name($name);
    return $self;
}

sub _set_name {
    my $self = shift;
    $self->{__name} = shift || return $self->{__name};
}

sub set_prefix {
    my $self   = shift;
    my $prefix = shift;
    if ( defined $prefix ) {
        $self->{__prefix} = $prefix;
        $self->set_ns_uri( $self->ns->get_uri($prefix) );
    }
    $self->{__prefix};
}

sub ns {
    return $_[0]->_context;
}

=head2 add_namespace $prefix => $namespace_uri

Add Namespace mapping 

=cut

sub add_namespace {
    my $self = shift;
    my ( $prefix, $ns_uri ) = @_;
    my $default1_uri = $self->ns->get_uri('');
    $self->ns->declare_prefix(@_);
    my $default2_uri = $self->ns->get_uri('');
    unless ( $default1_uri ne $default2_uri ) {
        $self->set_prefix('') unless $self->set_prefix;
    }
}

sub set_ns_uri {
    my $self = shift;
    $self->{__ns_iri} = shift if @_;
    $self->{__ns_iri};
}

=head2 default_uri

Return default Namespace_uri for elemnt scope

=cut

sub default_uri {
    $_[0]->ns->get_uri('');
}

sub name {
    return $_[0]->_set_name();
}

=head2 local_name

Return localname of elemnt ( without prefix )

=cut

sub local_name {
    return $_[0]->_set_name();
}

=head2 to_sax2

Export elemnt as SAX2 struct

=cut

sub to_sax2 {
    my $self = shift;
    my $res  = {
        Prefix     => $self->set_prefix,
        LocalName  => $self->local_name,
        Attributes => $self->attributes->to_sax2,
        Name       => $self->set_prefix
        ? $self->set_prefix() . ":" . $self->local_name
        : $self->local_name,
        NamespaceURI => $self->set_prefix ? $self->set_ns_uri() : '',
    };
    return $res;
}

sub attrs_by_prefix {
    my $self = shift;
    return $self->attributes->by_prefix(@_);
}

sub attrs_by_ns_uri {
    my $self = shift;
    return $self->attributes->by_ns_uri(@_);
}
=head2 skip_content

Skip entry of element. Return $self

=cut

sub skip_content {
    my $self = shift;
    return 1 if $self->is_skip_content;
    $self->is_skip_content(1);
    $self;
}

sub is_skip_content {
    my $self = shift;
    $self->_skip_content(@_) || 0
}

=head delete_element

Delete start and close element from stream. return $self

=cut

sub delete_element {
    my $self = shift;
    return 1 if $self->is_delete_element;
    $self->is_delete_element(1);
    $self;
}

sub is_delete_element {
    my $self = shift;
    $self->_delete_element(@_) || 0
}

1;
