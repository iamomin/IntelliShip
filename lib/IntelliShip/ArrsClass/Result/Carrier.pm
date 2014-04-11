use utf8;
package IntelliShip::ArrsClass::Result::Carrier;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::Carrier

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

=head1 TABLE: C<carrier>

=cut

__PACKAGE__->table("carrier");

=head1 ACCESSORS

=head2 carrierid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 carriername

  data_type: 'varchar'
  is_nullable: 1
  size: 500

=head2 carrierphone

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 groupname

  data_type: 'varchar'
  is_nullable: 0
  size: 35

=head2 halocarrierid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 datetransitupdated

  data_type: 'timestamp'
  is_nullable: 1

=head2 transitemail

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 require3rdpartyaddress

  data_type: 'integer'
  is_nullable: 1

=head2 transitthreshold

  data_type: 'integer'
  is_nullable: 1

=head2 scac

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=cut

__PACKAGE__->add_columns(
  "carrierid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "carriername",
  { data_type => "varchar", is_nullable => 1, size => 500 },
  "carrierphone",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "groupname",
  { data_type => "varchar", is_nullable => 0, size => 35 },
  "halocarrierid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "datetransitupdated",
  { data_type => "timestamp", is_nullable => 1 },
  "transitemail",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "require3rdpartyaddress",
  { data_type => "integer", is_nullable => 1 },
  "transitthreshold",
  { data_type => "integer", is_nullable => 1 },
  "scac",
  { data_type => "varchar", is_nullable => 1, size => 10 },
);

=head1 PRIMARY KEY

=over 4

=item * L</carrierid>

=back

=cut

__PACKAGE__->set_primary_key("carrierid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2gPHKuKc6+0+0YmD91QFtw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
