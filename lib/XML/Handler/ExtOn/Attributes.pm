package XML::Handler::ExtOn::Attributes;

use Carp;
use Data::Dumper;
use XML::Handler::ExtOn::TieAttrs;
for my $key (qw/ _context _a_stack/) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}
use strict;
use warnings;

sub new {
    my ( $class, %attr ) = @_;
    my $self = bless {}, $class;
    $self->_context( $attr{context} ) or die "not exists context parametr";
    my @a_stack = ();
    if ( my $sax2 = $attr{sax2} ) {

        #walk through sax2 attrs
        # and register namespaces
        for ( values %$sax2 ) {
            my ( $prefix, $ns_uri ) = ( $_->{Prefix}, $_->{NamespaceURI} );
            if ( defined $prefix && $prefix eq 'xmlns' ) {
                $self->_context->declare_prefix( $_->{LocalName}, $_->{Value} );
            }

            #set default namespace
            if ( $_->{Name} eq 'xmlns' ) {

                #warn "register deafault ns".$a->{Value};
                $self->_context->declare_prefix( '', $_->{Value} );
            }
        }

        #now set default namespaces
        # and
        for ( values %$sax2 ) {

            #save original data from changes
            my %val = %{$_};
            $val{NamespaceURI} = $self->_context->get_uri('')
              unless $val{Prefix} || $val{Name} eq 'xmlns';
            push @a_stack, \%val;
        }

    }
    $self->_a_stack( \@a_stack );
    return $self;
}

=head2 to_sax2

Export attributes to sax2 structures

=cut

sub to_sax2 {
    my $self  = shift;
    my $attrs = $self->_a_stack;
    my %res   = ();
    foreach my $rec (@$attrs) {
        my %val = %{$rec};

        #clean default uri
        $val{NamespaceURI} = undef unless $val{Prefix};

        my $key = "{" . ( $val{NamespaceURI} || '' ) . "}$val{LocalName}";
        $res{$key} = \%val

          #        warn Dumper $rec;
    }
    return \%res;
}

sub ns {
    return $_[0]->_context;
}

sub by_prefix {
    my $self   = shift;
    my $prefix = shift;
    my %hash   = ();
    my $ns_uri = $self->ns->get_uri($prefix)
      or die "get_uri($prefix) return undef";
    tie %hash, 'XML::Handler::ExtOn::TieAttrs', $self->{__attrs},
      by       => 'Prefix',
      value    => $prefix,
      template => {
        Value        => '',
        NamespaceURI => $ns_uri,
        Name         => '',
        LocalName    => '',
        Prefix       => ''
      };
    return \%hash;
}

sub by_ns_uri {
    my $self   = shift;
    my $ns_uri = shift;
    my %hash   = ();
    my $prefix = $self->ns->get_prefix($ns_uri)
      or die "get_prefix($ns_uri) return undef";
    tie %hash, 'XML::Handler::ExtOn::TieAttrs', $self->{__attrs},
      by       => 'NamespaceURI',
      value    => $ns_uri,
      template => {
        Value        => '',
        NamespaceURI => '',
        Name         => '',
        LocalName    => '',
        Prefix       => $prefix
      };
    return \%hash

}
1;
