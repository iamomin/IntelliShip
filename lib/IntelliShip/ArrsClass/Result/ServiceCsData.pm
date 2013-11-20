use utf8;
package IntelliShip::ArrsClass::Result::ServiceCsData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::ServiceCsData

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

=head1 TABLE: C<servicecsdata>

=cut

__PACKAGE__->table("servicecsdata");

=head1 ACCESSORS

=head2 servicecsdataid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 ownertypeid

  data_type: 'integer'
  is_nullable: 1

=head2 ownerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 datatypeid

  data_type: 'integer'
  is_nullable: 1

=head2 datatypename

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 datecreated

  data_type: 'timestamp'
  is_nullable: 1

=head2 datehalocreated

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "servicecsdataid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "ownertypeid",
  { data_type => "integer", is_nullable => 1 },
  "ownerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "datatypeid",
  { data_type => "integer", is_nullable => 1 },
  "datatypename",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "datecreated",
  { data_type => "timestamp", is_nullable => 1 },
  "datehalocreated",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</servicecsdataid>

=back

=cut

__PACKAGE__->set_primary_key("servicecsdataid");

=head1 UNIQUE CONSTRAINTS

=head2 C<servicecsdata_unique>

=over 4

=item * L</ownertypeid>

=item * L</ownerid>

=item * L</datatypeid>

=item * L</datatypename>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "servicecsdata_unique",
  ["ownertypeid", "ownerid", "datatypeid", "datatypename"],
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o9K8/+KIuDw9GEbUr4axRQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
