#!/usr/bin/perl
#

package Shopping::Basket::Product;

use Mouse;

extends 'Shopping::Basket';

has 'product_db' => (is => 'rw', isa => 'Str', default => 'products');
has 'product_couch' => ( is => 'rw', isa => 'Store::CouchDB', default => sub{Store::CouchDB->new});

sub BUILD {
    my $self = shift;

    $self->product_couch->host($self->couch_host);
    $self->product_couch->port($self->couch_port);
    $self->product_couch->db($self->product_db);
}


sub get_product {
    my ($self, $product) = @_;

    my $view = { view => 'product/by_name',
        opts => {
            key   => '"' . $product . '"',
            include_docs => 'true',
        },
    };
    my $res = $self->product_couch->get_view($view);
    return $res->{$product} || undef;
}

sub get_product_price {
    my ($self, $product) = @_;

    my $view = { view => 'product/'.lc($self->currency),
        opts => {
            key   => '"' . $product . '"',
        },
    };
    my $res = $self->product_couch->get_view($view);
    #TODO add a pricing plugin
    return $res->{$product}->{value} || undef;
}

