use utf8;
package IntelliShip::ArrsClass::Result::RateSummary;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::RateSummary

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<ratesummary>

=cut

__PACKAGE__->table("ratesummary");

=head1 ACCESSORS

=head2 ratesummaryid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 sopid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 carrierid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 startdate

  data_type: 'date'
  is_nullable: 1

=head2 stopdate

  data_type: 'date'
  is_nullable: 1

=head2 defaultcharges

  data_type: 'real'
  is_nullable: 1

=head2 bandstartweek

  data_type: 'integer'
  is_nullable: 1

=head2 bandmaxweek

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ratesummaryid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "sopid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "carrierid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "startdate",
  { data_type => "date", is_nullable => 1 },
  "stopdate",
  { data_type => "date", is_nullable => 1 },
  "defaultcharges",
  { data_type => "real", is_nullable => 1 },
  "bandstartweek",
  { data_type => "integer", is_nullable => 1 },
  "bandmaxweek",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ratesummaryid>

=back

=cut

__PACKAGE__->set_primary_key("ratesummaryid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/iqUORTZm+oeqtW23qvGQA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
