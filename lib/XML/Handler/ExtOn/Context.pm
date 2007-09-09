package XML::Handler::ExtOn::Context;
use strict;
use warnings;
use Data::Dumper;
use Tie::UnionHash;
### install get/set accessors for this object.
for my $key ( qw/ __changes_hash __context_map/ ) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}
sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless( {}, $class );
    my %args = @_;
    my $map = $args{parent_map} || {xmlns=>'http://www.w3.org/2000/xmlns/'};
    my %changes = ();
    $self->__changes_hash(\%changes);
    my %new_map = ();
    tie %new_map, 'Tie::UnionHash', $map, \%changes;
    $self->__context_map(\%new_map);
    return $self;
}
=head2 sub_context

create sub_context

=cut
sub sub_context {
    my $self = shift;
    return __PACKAGE__->new( parent_map=>$self->get_map )

}

sub get_changes {
    my $self = shift;
    return $self->__changes_hash;
}
sub get_map {
    my $self = shift;
    return $self->__context_map;
}

sub get_uri {
    my $self = shift;
    my $prefix = shift;
    unless ( $prefix) {
        return $self->get_map->{$prefix} || $self->get_map->{xmlns} 
    }
    return  $self->get_map->{$prefix};
}

sub get_prefix {
    my $self = shift;
    my $uri = shift;
    return  { reverse %{ $self->get_map } }->{$uri};
    
}
sub declare_prefix {
    my $self = shift;
    my %map = @_;
    my $current_map = $self->get_map;
    while (my ( $prefix, $uri) = each %map ) {
        $current_map->{$prefix} = $uri;
    }
    $current_map;
}

1;