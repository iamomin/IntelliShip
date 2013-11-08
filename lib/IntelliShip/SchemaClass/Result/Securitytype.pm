use utf8;
package IntelliShip::SchemaClass::Result::Securitytype;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::SchemaClass::Result::Securitytype

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

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<securitytype>

=cut

__PACKAGE__->table("securitytype");

=head1 ACCESSORS

=head2 securitytypeid

  data_type: 'integer'
  is_nullable: 0

=head2 securitytypename

  data_type: 'varchar'
  is_nullable: 0
  size: 35

=cut

__PACKAGE__->add_columns(
  "securitytypeid",
  { data_type => "integer", is_nullable => 0 },
  "securitytypename",
  { data_type => "varchar", is_nullable => 0, size => 35 },
);

=head1 PRIMARY KEY

=over 4

=item * L</securitytypeid>

=back

=cut

__PACKAGE__->set_primary_key("securitytypeid");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-30 19:40:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+5K9k9wRu6Km3yrSJe26hw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
