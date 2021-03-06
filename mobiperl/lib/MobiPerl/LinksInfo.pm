use warnings;
use strict;
package MobiPerl::LinksInfo;

#    Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    MobiPerl/LinksInfo.pm, Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use File::Temp qw/tempfile/;
use LWP::Simple;
use FindBin qw($RealBin);
use lib "$RealBin";

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $obj   = bless {
        LINKEXISTS        => {},
        RECORDINDEX       => 0,
        RECORDTOIMAGEFILE => {},
        COVEROFFSET       => -1,
        THUMBOFFSET       => -1,
        @_
    }, $class;
    return $obj;
}

sub link_exists {
    my $self = shift;
    return $self->{LINKEXISTS};
}

sub add_image_link {
    my $self  = shift;
    my $image = shift;
##    print STDERR "ADD_IMAGE_LINK: $image\n";
    $self->{RECORDINDEX}++;
    $self->{RECORDTOIMAGEFILE}->{ $self->get_record_index() } = $image;
}

sub add_cover_image {
    my $self  = shift;
    my $image = shift;
    $self->add_image_link($image);
    $self->{COVEROFFSET} = $self->get_record_index() - 1;
}

sub add_thumb_image {
    my $self  = shift;
    my $image = shift;
    $self->add_image_link($image);
    $self->{THUMBOFFSET} = $self->get_record_index() - 1;
}

sub get_cover_offset {
    my $self = shift;
    return $self->{COVEROFFSET};
}

sub get_thumb_offset {
    my $self = shift;
    return $self->{THUMBOFFSET};
}

sub get_record_index {
    my $self = shift;
    return $self->{RECORDINDEX};
}

sub get_image_file {
    my $self = shift;
    my $val  = shift;
    return $self->{RECORDTOIMAGEFILE}->{$val};
}

sub get_n_images {
    my $self = shift;
    my $res  = keys %{ $self->{RECORDTOIMAGEFILE} };
    return $res;
}

sub check_for_links {
    my $self = shift;
    my $html = shift;
    my $base_dir ='';
   $base_dir  = shift if (@_);


    for ( @{ $html->extract_links('img') } ) {
        my ( $link, $element, $attr, $tag ) = @$_;

        if ( $tag eq "img" ) {
            my $src = $element->attr("src");
            my $file = File::Spec->catfile($base_dir,$src);
            if ( -e $file ) {
                # Onlys save link if image exists.
                $element->attr( "src", undef );
                $self->{RECORDINDEX}++;
                $element->attr( "recindex",
                    sprintf( "%05d", $self->{RECORDINDEX} ) );
                $self->{RECORDTOIMAGEFILE}->{ $self->{RECORDINDEX} } = $file;
            }
            elsif ( $src =~ /^(?:file|https?):/ ) {
                eval {
                    ;
                    my ( $fh, $filename ) = tempfile();
                    my $data = LWP::Simple::get($src);
                    print $fh $data || die $!;
                    close($fh);
                    $element->attr( "src", undef );
                    $self->{RECORDINDEX}++;
                    $element->attr( "recindex",
                        sprintf( "%05d", $self->{RECORDINDEX} ) );
                    $self->{RECORDTOIMAGEFILE}->{ $self->{RECORDINDEX} } =
                      $filename;
                };
            }
            else {
                print STDERR "Warning: Image file does not exists: $src\n";
            }
            next;
        }
        print STDERR "LINK: $tag $link $attr at ", $element->address(), " ";

        #	print STDERR $element->as_HTML;
    }
}

return 1;
