# /packages/intranet-timesheet2-workflow/www/absence-panel.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# https://www.project-open.com/license/ for details.

# -----------------------------------------------------------
# Page Head
# 
# There are two different heads, depending whether it's called
# "standalone" (TCL-page) or as a Workflow Panel.
# -----------------------------------------------------------

if {[info exists task]} {

    # Workflow-Panel Head:
    # This code is called when this page is embedded in a WF "Panel"

    set task_id $task(task_id)
    set case_id $task(case_id)

    # Return-URL Logic
    set return_url ""
    if {[info exists task(return_url)]} { set return_url $task(return_url) }

    set absence_id [db_string pid "select object_id from wf_cases where case_id = :case_id" -default ""]

} else {

    # Stand-Alone Head:
    # This code is called when the page is used as a normal "EditPage" or "NewPage".

    ad_page_contract {
        Purpose: form to add a new project or edit an existing one
    } {
        absence_id:integer
        { return_url "/intranet/" }
	{ task_id "" }
    }

    # Get the task_id if we've got the project
    if {"" == $task_id} { 
	set case_id [db_string case_id "select case_id from wf_cases where object_id = :absence_id" -default 0]
	set tasks [db_list tasks "select task_id from wf_tasks where case_id=:case_id and state in ('started', 'enabled')"]
	switch [llength $tasks] {
	    0 { ad_return_complaint 1 "Didn't find task for project \#$project_id" }
	    1 {
		set task_id [lindex $tasks 0]
	    }
	    default {
		# Multiple tasks found.
		# Take just any one assigned to the user, because the user needs to do
		# all of them anyway.
		foreach tid $tasks {
			array set task_info [wf_task_info $tid]
			if {$task_info(this_user_is_assigned_p)} { set task_id $tid}
		}

		if {"" == $task_id} {
		    ad_return_complaint 1 "You are not assigned to any task in project \#$project_id"
		}
	    }
	}
    }

    if {[catch {
	array set task [wf_task_info $task_id]
    } err_msg]} {
                ad_return_complaint 1 "<li><b>Task \#$task_id nicht gefunden</b>:<p>
			Dieser Fehler kann auftreten, wenn ein Administrator einen RFC
			'hart' gel&ouml;scht hat. Im normalen Betrieb sollte das nicht
			passieren.<p>
			Bitte kontaktieren Sie Ihren System Administrator.<p>
		"
		return
    }


    set page_title [lang::message::lookup "" intranet-timesheet2-workflow.Absence "Absence"]
    set context_bar [im_context_bar [list /intranet-rfc/projects/ "[lang::message::lookup "" intranet-timesheet2-workflow.Absences "Absences"]"] $page_title]
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set transition_key [db_string transition_key "select transition_key from wf_tasks where task_id = :task_id" -default ""]
set current_user_id [auth::require_login]
set object_name [db_string name "select acs_object__name(:absence_id)"]

db_1row absence_info "
	select	ua.owner_id as user_id_from_search,
		ua.absence_type_id,
		ua.duration_days
	from	im_user_absences ua
	where	absence_id = :absence_id
"

db_1row employee_info "
	select	e.vacation_balance
	from	im_employees e
	where	employee_id = :user_id_from_search
"

set html ""

# ---------------------------------------------------------------
# Show a warning if the vacation balance - days requested is negative
# ... only if it's a vacation
# ---------------------------------------------------------------

if {$absence_type_id in [im_sub_categories [im_user_absence_type_vacation]]} { 
    set remaining_vacation_balance [expr ($vacation_balance+0) - ($duration_days+0)]
    if {$remaining_vacation_balance < 0} {
	set exceeding_vacation_balance [expr -1 * $remaining_vacation_balance]
	set warning_default "Warning: Vacation balance exceeded by %exceeding_vacation_balance% days"
	set warning_l10n [lang::message::lookup "" intranet-timesheet2-workflow.Vacation_balance_exceeded_by $warning_default]
	append html "<h2><font color=red>$warning_l10n</font></h2>"
    }
}

# ---------------------------------------------------------------
# Get the included hours
# ---------------------------------------------------------------

set params [list \
		[list absence_id $absence_id] \
		[list return_url $return_url] \
		[list enable_master_p 0] \
		[list form_mode display] \
		[list panel_p 1] \
]
append html [ad_parse_template -params $params "/packages/intranet-timesheet2/www/absences/new"]


# ---------------------------------------------------------------
# Show the vacation balance of the user for whom the current_user
# needs to approve the absence. We could argue, that the current_
# user should be a supervisor because of the workflow logic.
# But maybe somebody else gets here?
# ---------------------------------------------------------------

# Get the user from the absence object
set user_id_from_search [db_string owner "select owner_id from im_user_absences where absence_id = :absence_id" -default $current_user_id]

set read_p 0
if {$user_id_from_search == $current_user_id} { set read_p 1 }
if {[im_permission $current_user_id view_hr]} { set read_p 1 }
if {[im_permission $current_user_id view_absences_all]} { set read_p 1 }
if {$read_p} {
    set params [list \
		    [list user_id_from_search $user_id_from_search] \
		    [list return_url [im_url_with_query]] \
    ]

    set vacation_balance_html [ad_parse_template -params $params "/packages/intranet-timesheet2/www/absences/vacation-balance-component"]
    append html "
        [im_box_header "Vacation Balance"]
        $vacation_balance_html
        [im_box_footer]
    "
}

