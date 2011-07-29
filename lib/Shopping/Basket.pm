#!/usr/bin/perl -Ilib

package Shopping::Basket;

use Mouse;
use Data::UUID;
use Shopping::Basket::Product;

=head1 NAME

Shopping::Basket - The great new Shopping::Basket!

=head1 VERSION

Version 0.01.01.01.01.01.01.01.01.01.01.01

=cut

our $VERSION = '0.01';

has 'debug' => (is => 'rw', isa => 'Bool', default => 0, predicate => 'is_debug');
has 'basket_db' => (is => 'rw', isa => 'Str', default => 'basket');
has 'couch_host' => (is => 'rw', isa => 'Str', default => '127.0.0.1');
has 'couch_port' => (is => 'rw', isa => 'Str', default => '5984');
has 'couch' => ( is => 'rw', isa => 'Store::CouchDB', default => sub{Store::CouchDB->new});
has 'tax' => (is => 'rw', isa => 'Int', default => 0);
has 'discount' => (is => 'rw', isa => 'Int', default => 0);
has 'basket_id' => (is => 'rw', isa => 'Str', default => sub{Data::UUID->new->create_str});
has 'currency' => (is => 'rw', isa => 'Str', default => 'NZD');
has 'notify' => (is => 'rw', isa =>'Str');

sub BUILD {
    my $self = shift;

    $self->couch->host($self->couch_host);
    $self->couch->port($self->couch_port);
    $self->couch->db($self->basket_db);
}

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Shopping::Basket;

    my $foo = Shopping::Basket->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 basket_add

=cut

sub add {
    my ( $self, $item ) = @_;

    my $doc = {
        type => 'item',
        timestamp => time,
        basket => $self->basket_id,
    };
    foreach my $ky (keys %{$item}){
        $doc->{$ky} = $item->{$ky};
    }

    if ( $self->tax ) {
        $doc->{tax} = $self->tax;
    }
    if ( $self->discount ) {
        $doc->{price} = $self->get_discount($doc->{price});
    }

    my $res = $self->couch->put_doc( {doc => $doc } );
    return $res;
}

sub count {
    my ( $self ) = @_;

    my $view = { view => 'basket/count_by_session',
        opts => {
            group => 'true',
            key   => '"' . $self->basket_id . '"',
        },
    };
    my $res = $self->couch->get_view($view);
    return $res->{$self->basket_id}->{value};
}

sub delete {
    my ( $self, $id ) = @_;
    return unless $id;
    my $doc = $self->couch->get_doc( { id => $id } );
    return unless $doc;
    if ( $doc->{basket} eq $self->basket_id ) {
        $self->couch->del_doc($doc);
    }
    return;
}

sub cleanup {
    my ( $self ) = @_;

    my $items = $self->load();
    foreach my $doc ( @{ $items } ) {
        if ( $doc->{basket} eq $self->basket_id ) {
            $self->couch->del_doc( $doc );
        }
    }
    return;
}

sub get_total {
    my ( $self ) = @_;
    my $view = { view => 'basket/total_by_basket',
        opts => {
            group => "true",
            key   => '"' . $self->basket_id . '"',
        },
    };
    my $res = $self->couch->get_view($view);
    return $res->{$self->basket_id};
}

sub load {
    my ( $self ) = @_;

    my $view = { view => 'basket/by_session',
        opts => { key => '"' . $self->basket_id . '"' },
      };
    my $res = $self->couch->get_array_view($view);
    my @items;
    foreach my $doc ( @{$res} ) {
        next unless $doc;
        $doc->{id} = $doc->{_id};
        if($doc->{currency} ne $self->currency){
            $doc = $self->item_needs_curr_update($doc);
        }
        if ( $self->tax ) {
            if ( $doc->{tax}
                && ( $doc->{tax} == $self->tax ) )
            {
                push( @items, $doc );
            }
            else {
                $doc = $self->item_needs_tax_update($doc);
                push( @items, $doc );
            }
        }
        else {
            push( @items, $doc );
        }
    }
    return \@items;
}

sub item_needs_tax_update {
    my ( $self, $doc ) = @_;
    
    $doc->{tax} = $self->tax;
    $self->couch->update_doc( { name => $doc->{id}, doc => $doc } );
    return $doc;
}

sub item_needs_curr_update {
    my ( $self, $doc ) = @_;

    $doc->{price} = $self->get_product_price($doc->{product_key});
    $doc->{currency} = $self->currency;

    $self->couch->update_doc( { name => $doc->{id}, doc => $doc } );
    $self->notify = 'Your account currency is '.$self->currency.' so we converted your shopping cart';
    return $doc;
}

sub get_discount {
    my ( $self, $item_price ) = @_;

    # TODO implement discount engine (plugin?)
    my $price;
    return $price;
}

=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-shopping-basket at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Shopping-Basket>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Shopping::Basket


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Shopping-Basket>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Shopping-Basket>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Shopping-Basket>

=item * Search CPAN

L<http://search.cpan.org/dist/Shopping-Basket/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of Shopping::Basket
