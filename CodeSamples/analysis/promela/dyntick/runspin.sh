#!/bin/sh
#
# Run a test.  Specify the test type as the first argument, for example:
#
#	sh runtest.sh base
#
# will run the "dyntickRCU-base.spin model".  Be sure to edit the
# MAX_DYNTICK_LOOP_* parameters as needed to fit your needs and
# memory size.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# Copyright (c) 2008 Paul E. McKenney, IBM Corporation.

type=${1-irq-nmi-ssl}
spin -a dyntickRCU-$type.spin
cc -DSAFETY -o pan pan.c
grep '^#.*DYN' dyntickRCU-$type.spin
./pan
