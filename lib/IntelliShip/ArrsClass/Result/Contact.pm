use utf8;
package IntelliShip::ArrsClass::Result::Contact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::Contact

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

=head1 TABLE: C<contact>

=cut

__PACKAGE__->table("contact");

=head1 ACCESSORS

=head2 contactid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 customerid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 keyringid

  data_type: 'char'
  is_nullable: 1
  size: 13

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 firstname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 lastname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 phonemobile

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 phonebusiness

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 datecreated

  data_type: 'date'
  is_nullable: 1

=head2 datedeactivated

  data_type: 'date'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "contactid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "customerid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "keyringid",
  { data_type => "char", is_nullable => 1, size => 13 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "lastname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "phonemobile",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "phonebusiness",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "datecreated",
  { data_type => "date", is_nullable => 1 },
  "datedeactivated",
  { data_type => "date", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</contactid>

=back

=cut

__PACKAGE__->set_primary_key("contactid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:togW3DjOk2MLNvGbsZb3xQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
