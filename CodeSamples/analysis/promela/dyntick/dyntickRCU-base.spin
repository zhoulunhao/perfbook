/*
 * Tests a variation of RCU-dyntick interaction in the Linux 2.6.25-rc4
 * kernel.  Note that portions of this are derived from Linux kernel code,
 * portions of which are licensed under a GPLv2-only license.
 *
 * This version omits irq/NMI handlers.  It does not have either safety
 * or liveness checks.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * Copyright (c) 2008 IBM Corporation.
 */

/*
 * Parameters:
 *
 * MAX_DYNTICK_LOOP_NOHZ: The number of non-idle process level bursts
 *	of work.
 *
 * Setting a given value for a given parameter covers all values up to
 * and including the specified value.  So, if MAX_DYNTICK_LOOP_NOHZ is
 * set to "2", then the validation will cover 0, 1, and 2 loops.
 */

#define MAX_DYNTICK_LOOP_NOHZ 3

/* Variables corresponding to the 2.6.25-rc4 per-CPU variables. */

byte dynticks_progress_counter = 0;
byte rcu_update_flag = 0;
byte in_interrupt = 0;

/*
 * Validation code for the slice of the preemptible-RCU code that
 * interacts with the dynticks subsystem.  This is set up to match
 * the code in 2.6.25-rc4, namely dyntick_save_progress_counter(),
 * rcu_try_flip_waitack_needed(), rcu_try_flip_waitmb_needed(),
 * and portions of rcu_try_flip_waitack() and rcu_try_flip_waitmb().
 */

proctype grace_period()
{
	byte curr;
	byte snap;

	/*
	 * A little code from rcu_try_flip_idle() and its call
	 * to dyntick_save_progress_counter().
	 */

	atomic {
		printf("MAX_DYNTICK_LOOP_NOHZ = %d\n", MAX_DYNTICK_LOOP_NOHZ);
		snap = dynticks_progress_counter;
	}

	/*
	 * Each pass through the following loop corresponds to an
	 * invocation of the scheduling-clock interrupt handler,
	 * specifically a little code from rcu_try_flip_waitack()
	 * and its call to rcu_try_flip_waitack_needed().
	 */

	do
	:: 1 ->
		atomic {
			curr = dynticks_progress_counter;
			if
			:: (curr == snap) && ((curr & 1) == 0) ->
				break;
			:: (curr - snap) > 2 || (snap & 1) == 0 ->
				break;
			:: 1 -> skip;
			fi;
		}
	od;

	/*
	 * A little code from rcu_try_flip_waitzero() and its call
	 * to dyntick_save_progress_counter(), plus a bunch of
	 * validation code.
	 */

	snap = dynticks_progress_counter;

	/*
	 * Each pass through the following loop corresponds to an
	 * invocation of the scheduling-clock interrupt handler,
	 * specifically a little code from rcu_try_flip_waitmb()
	 * and its call to rcu_try_flip_waitmb_needed().
	 */

	do
	:: 1 ->
		atomic {
			curr = dynticks_progress_counter;
			if
			:: (curr == snap) && ((curr & 1) == 0) ->
				break;
			:: (curr != snap) ->
				break;
			:: 1 -> skip;
			fi;
		}
	od;
}

/*
 * Validation code for the rcu_enter_nohz() and rcu_exit_nohz()
 * functions.  Each pass through this process's loop corresponds
 * to exiting nohz mode, then re-entering it.  This code also
 * includes assertions corresponding to the WARN_ON() calls in
 * rcu_exit_nohz() and rcu_enter_nohz().
 */

proctype dyntick_nohz()
{
	byte tmp;
	byte i = 0;

	do
	:: i >= MAX_DYNTICK_LOOP_NOHZ -> break;
	:: i < MAX_DYNTICK_LOOP_NOHZ ->

		/*
		 * The following corresponds to rcu_exit_nohz().
		 */

		tmp = dynticks_progress_counter;
		atomic {
			dynticks_progress_counter = tmp + 1;
			assert((dynticks_progress_counter & 1) == 1);
		}

		/*
		 * The following corresponds to rcu_enter_nohz().
		 */

		tmp = dynticks_progress_counter;
		atomic {
			dynticks_progress_counter = tmp + 1;
			assert((dynticks_progress_counter & 1) == 0);
		}
		i++;
	od;
}

init {
	atomic {
		run dyntick_nohz();
		run grace_period();
	}
}
