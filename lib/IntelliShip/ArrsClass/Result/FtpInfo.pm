use utf8;
package IntelliShip::ArrsClass::Result::FtpInfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::FtpInfo

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

=head1 TABLE: C<ftpinfo>

=cut

__PACKAGE__->table("ftpinfo");

=head1 ACCESSORS

=head2 ftpinfoid

  data_type: 'char'
  is_nullable: 0
  size: 13

=head2 ftpinfotypeid

  data_type: 'integer'
  is_nullable: 1

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 address

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 path

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 active

  data_type: 'integer'
  is_nullable: 1

=head2 timeout

  data_type: 'integer'
  is_nullable: 1

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 carrierid

  data_type: 'char'
  is_nullable: 1
  size: 13

=cut

__PACKAGE__->add_columns(
  "ftpinfoid",
  { data_type => "char", is_nullable => 0, size => 13 },
  "ftpinfotypeid",
  { data_type => "integer", is_nullable => 1 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "address",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "path",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "active",
  { data_type => "integer", is_nullable => 1 },
  "timeout",
  { data_type => "integer", is_nullable => 1 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "carrierid",
  { data_type => "char", is_nullable => 1, size => 13 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ftpinfoid>

=back

=cut

__PACKAGE__->set_primary_key("ftpinfoid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VfBlmQDf7Sp960bCLFU+gQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
