use utf8;
package IntelliShip::SchemaClass::Result::Ucc128;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Ucc128

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

=head1 TABLE: C<ucc128>

=cut

__PACKAGE__->table("ucc128");

=head1 ACCESSORS

=head2 ucc128id

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 companyid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 sequencename

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 ucc128template

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 ucc128formula

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 ucc128copies

  data_type: 'integer'
  is_nullable: 1

=head2 companynamecriteria

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 companynameprecise

  data_type: 'integer'
  is_nullable: 1

=head2 departmentcriteria

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 departmentprecise

  data_type: 'integer'
  is_nullable: 1

=head2 custnumcriteria

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 custnumprecise

  data_type: 'integer'
  is_nullable: 1

=head2 externalpkcriteria

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 externalpkprecise

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ucc128id",
  { data_type => "char", is_nullable => 0, size => 13 },
  "companyid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "sequencename",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "ucc128template",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "ucc128formula",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "ucc128copies",
  { data_type => "integer", is_nullable => 1 },
  "companynamecriteria",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "companynameprecise",
  { data_type => "integer", is_nullable => 1 },
  "departmentcriteria",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "departmentprecise",
  { data_type => "integer", is_nullable => 1 },
  "custnumcriteria",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "custnumprecise",
  { data_type => "integer", is_nullable => 1 },
  "externalpkcriteria",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "externalpkprecise",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ucc128id>

=back

=cut

__PACKAGE__->set_primary_key("ucc128id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-26 01:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:je3aPwBTq727nMGA+UMSEA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
