package Array::Set;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Tie::IxHash;

use Exporter qw(import);
our @EXPORT_OK = qw(set_diff set_symdiff set_union set_intersect);

sub _doit {
    my $op = shift;

    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }

    tie my(%res), 'Tie::IxHash';

    my $ic  = $opts->{ignore_case};
    my $ib  = $opts->{ignore_blanks};
    my $ign = $ic || $ib;

    my $i = 0;
  SET:
    for my $i (1..@_) {
        my $set = $_[$i-1];

        if ($op eq 'union') {

            if ($ign) {
                for (@$set) {
                    my $k = $ic ? lc($_) : $_;
                    $k =~ s/\s+//g if $ib;
                    $res{$k} = $_ unless exists $res{$k};
                }
                # return result
                if ($i == @_) {
                    return [values %res];
                }
            } else {
                for (@$set) { $res{$_}++ }
                # return result
                if ($i == @_) {
                    return [keys %res];
                }
            }

        } elsif ($op eq 'intersect') {

            if ($ign) {
                if ($i == 1) {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        $res{$k} = [1,$_] unless exists $res{$k};
                    }
                } else {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        if ($res{$k} && $res{$k}[0] == $i-1) {
                            $res{$k}[0]++;
                        }
                    }
                }
                # return result
                if ($i == @_) {
                    return [map {$res{$_}[1]}
                                grep {$res{$_}[0] == $i} keys %res];
                }
            } else {
                if ($i == 1) {
                    for (@$set) { $res{$_} = 1 }
                } else {
                    for (@$set) {
                        if ($res{$_} && $res{$_} == $i-1) {
                            $res{$_}++;
                        }
                    }
                }
                # return result
                if ($i == @_) {
                    return [grep {$res{$_} == $i} keys %res];
                }
            }

        } elsif ($op eq 'diff') {

            if ($ign) {
                if ($i == 1) {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        $res{$k} = $_ unless exists $res{$k};
                    }
                } else {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        delete $res{$k};
                    }
                }
                # return result
                if ($i == @_) {
                    return [values %res];
                }
            } else {
                if ($i == 1) {
                    for (@$set) { $res{$_}++ }
                } else {
                    for (@$set) {
                        delete $res{$_};
                    }
                }
                # return result
                if ($i == @_) {
                    return [keys %res];
                }
            }

        } elsif ($op eq 'symdiff') {

            if ($ign) {
                if ($i == 1) {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        $res{$k} = [1,$_] unless exists $res{$k};
                    }
                } else {
                    for (@$set) {
                        my $k = $ic ? lc($_) : $_;
                        $k =~ s/\s+//g if $ib;
                        if (!$res{$k}) {
                            $res{$k} = [1, $_];
                        } elsif ($res{$k}[0] <= 2) {
                            $res{$k}[0]++;
                        }
                    }
                }
                # return result
                if ($i == @_) {
                    return [map {$res{$_}[1]}
                                grep {$res{$_}[0] == 1} keys %res];
                }
            } else {
                if ($i == 1) {
                    for (@$set) { $res{$_} = 1 }
                } else {
                    for (@$set) {
                        if (!$res{$_} || $res{$_} <= 2) {
                            $res{$_}++;
                        }
                    }
                }
                # return result
                if ($i == @_) {
                    return [grep {$res{$_} == 1} keys %res];
                }
            }

        }

    } # for set

    # caller does not specify any sets
    return [];
}

sub set_diff {
    _doit('diff', @_);
}

sub set_symdiff {
    _doit('symdiff', @_);
}

sub set_union {
    _doit('union', @_);
}

sub set_intersect {
    _doit('intersect', @_);
}

1;
# ABSTRACT: Perform set operations on arrays

=head1 SYNOPSIS

 use Array::Set qw(set_diff set_symdiff set_union set_intersect);

 set_diff([1,2,3,4], [2,3,4,5]);            # => [1]
 set_diff([1,2,3,4], [2,3,4,5], [3,4,5,6]); # => [1]
 set_diff({ci=>1}, ["a","b"], ["B","c"]);   # => ["a"]

 set_symdiff([1,2,3,4], [2,3,4,5]);            # => [1,5]
 set_symdiff([1,2,3,4], [2,3,4,5], [3,4,5,6]); # => [1,6]

 set_union([1,3,2,4], [2,3,4,5]);            # => [1,3,2,4,5]
 set_union([1,3,2,4], [2,3,4,5], [3,4,5,6]); # => [1,3,2,4,5,6]

 set_intersect([1,2,3,4], [2,3,4,5]);            # => [2,3,4]
 set_intersect([1,2,3,4], [2,3,4,5], [3,4,5,6]); # => [3,4]


=head1 DESCRIPTION

This module provides routines for performing set operations on arrays. Set is
represented as a regular Perl array. All comparison is currently done with C<eq>
(string comparison) so currently no support for references/objects/undefs. You
have to make sure that the arrays do not contain duplicates/undefs.

Characteristics and differences with other similar modules:

=over

=item * simple functional (non-OO) interface

=item * functions accept more than two arguments

=item * option to do case-insensitive comparison

=item * option to ignore blanks

=item * preserves ordering

=back

B<NOTE: This early release is a pretty direct port/translation from App::setop,
and is not as optimized as I'd like it to be. More optimizations will be done in
the future.> If you want more speed, I'd recommend L<Set::Object> (also supports
references/objects and performing operations on 3+ sets, XS) or simply
L<List::MoreUtils> (very popular module, offers XS version).


=head1 FUNCTIONS

All functions are not exported by default, but exportable.

=head2 set_diff([ \%opts ], \@set1, ...) => array

Perform difference (find elements in the first set not in the other sets).
Accept optional hashref as the first argument for options. Known options:

=over

=item * ignore_case => bool (default: 0)

If set to 1, will perform case-insensitive comparison.

=item * ignore_blanks => bool (default: 0)

If set to 1, will ignore blanks (C<" foo"> == C<"foo"> == C<"f o o">).

=back

=head2 set_symdiff([ \%opts ], \@set1, ...) => array

Perform symmetric difference (find elements in the first set not in the other
set, as well as elements in the other set not in the first). Accept optional
hashref as the first argument for options. See C<set_diff> for known options.

=head2 set_union([ \%opts ], \@set1, ...) => array

Perform union (find elements in the first or in the other, duplicates removed).
Accept optional hashref as the first argument for options. See C<set_diff> for
known options.

=head2 set_intersect([ \%opts ], \@set1, ...) => array

Perform intersection (find elements common in all the sets). Accept optional
hashref as the first argument for options. See C<set_diff> for known options.


=head1 SEE ALSO

L<App::setop> to perform set operations on lines of files on the command-line.

L<Array::Utils>, L<Set::Scalar>, L<List::MoreUtils> (C<uniq> for union,
C<singleton> for symmetric diff), L<Set::Array>, L<Array::AsObject>,
L<Set::Object>, L<Set::Tiny>.

=cut
