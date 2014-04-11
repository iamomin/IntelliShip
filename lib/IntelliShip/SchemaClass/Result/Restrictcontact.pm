use utf8;
package IntelliShip::SchemaClass::Result::Restrictcontact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Restrictcontact

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

=head1 TABLE: C<restrictcontact>

=cut

__PACKAGE__->table("restrictcontact");

=head1 ACCESSORS

=head2 restrictcontactid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 contactid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 fieldname

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 fieldvalue

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=cut

__PACKAGE__->add_columns(
  "restrictcontactid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "contactid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "fieldname",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "fieldvalue",
  { data_type => "varchar", is_nullable => 1, size => 200 },
);

=head1 PRIMARY KEY

=over 4

=item * L</restrictcontactid>

=back

=cut

__PACKAGE__->set_primary_key("restrictcontactid");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jFWTlid2PaMNo359K/CxOg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
