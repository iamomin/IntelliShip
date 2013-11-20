use utf8;
package IntelliShip::ArrsClass::Result::ServiceType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

IntelliShip::ArrsClass::Result::ServiceType

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

=head1 TABLE: C<servicetype>

=cut

__PACKAGE__->table("servicetype");

=head1 ACCESSORS

=head2 servicetypeid

  data_type: 'integer'
  is_nullable: 0

=head2 serivetypename

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "servicetypeid",
  { data_type => "integer", is_nullable => 0 },
  "serivetypename",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-20 04:13:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SszaWa0eP+8qSP0OwizJ3g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
