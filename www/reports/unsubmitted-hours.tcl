# /packages/intranet-timesheet2-workflow/www/unsubmitted-hours.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
    Report listing all main projects in the system with all available
    fields + DynFields from projects and customers
} {
    { level_of_detail 2 }
    { start_date "" }
    { end_date "" }
    { output_format "html" }
    { number_locale "" }
    { project_id:integer 0}
    { company_id:integer 0}
    { project_status_id:integer 0}
    { project_type_id:integer 0}
    { member_id:integer 0}
    { project_lead_id:integer 0}
}


# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
set menu_label "reporting-unsubmitted-hours"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default "f"]

if {"t" != $read_p} {
    ad_return_complaint 1 "
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    ad_script_abort
}


# ------------------------------------------------------------
# Constants

set locale [lang::user::locale]
if {"" == $number_locale} { set number_locale $locale  }
set date_format "YYYY-MM-DD"
set number_format "999,999.99"


# Check that Start & End-Date have correct format
if {"" != $start_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" != $end_date && ![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

set page_title [lang::message::lookup "" intrant-timesheet2-workflow.Unsubmitted_Hours "Unsubmitted Hours"]
set context_bar [im_context_bar $page_title]
set context ""

set levels [list 1 [lang::message::lookup "" intranet-timesheet2-workflow.User_Only "User Only"] 2 [lang::message::lookup "" intranet-timesheet2-workflow.User_and_Month "User + Month"] 3 [lang::message::lookup "" intranet-timesheet2-workflow.All_Details "All Details"]]



# ------------------------------------------------------------
# Defaults

if {"" == $start_date} { set start_date "2000-01-01" }
if {"" == $end_date} { set end_date "2099-12-31" }

# Maxlevel is 4. Normalize in order to show the right drop-down element
if {$level_of_detail > 3} { set level_of_detail 3 }

set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-timesheet2-workflow/reports/unsubmitted-hours" {start_date end_date level_of_detail project_id project_lead_id} ]

# BaseURL for drill-down. Needs company_id, project_id, user_id, level_of_detail
set base_url [export_vars -base "/intranet-timesheet2-workflow/reports/unsubmitted-hours" {start_date end_date}]


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]
if {0 != $project_id && "" != $project_id} { lappend criteria "p.project_id = :project_id" }
if {0 != $project_status_id && "" != $project_status_id} { lappend criteria "p.project_status_id in ([join [im_sub_categories $project_status_id] ","])" }
if {0 != $project_type_id && "" != $project_type_id} { lappend criteria "p.project_type_id in ([join [im_sub_categories $project_type_id] ","])" }
if {0 != $project_lead_id && "" != $project_lead_id} { lappend criteria "main_p.project_lead_id = :project_lead_id" }
if {0 != $company_id && "" != $company_id} { lappend criteria "p.company_id = :company_id" }
if {0 != $member_id && "" != $member_id} { lappend criteria "h.user_id = :member_id" }

set where_clause [join $criteria " and\n\t\t"]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# List of project variables to show

set hours_monthly_sum_counter [list \
        pretty_name "Hours Monthly" \
        var hours_monthly_sum \
        reset "\$user_day_month" \
        expr "\$hours+0" \
]

set hours_subtotal_counter [list \
        pretty_name "Hours Subtotal" \
        var hours_subtotal \
        reset \$user_id \
        expr "\$hours+0" \
]

set counters [list \
		  $hours_monthly_sum_counter \
		  $hours_subtotal_counter \
]


# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set sql "

	select	*,
		to_char(day, :date_format) as day_pretty,
		to_char(day, 'YYYY-MM') as day_month,
		im_name_from_user_id(user_id) as user_name,
		im_name_from_user_id(main_project_lead_id) as main_project_lead_name,
		user_id || '-' || to_char(day, 'YYYY-MM') as user_day_month
	from	(
		select
			h.day,
			h.user_id,
			main_p.project_id as main_project_id,
			main_p.project_name as main_project_name,
			main_p.project_lead_id as main_project_lead_id,
			c.company_id,
			c.company_name,
			sum(h.hours) as hours
		from
			im_hours h,
			im_projects p,
			im_projects main_p,
			im_companies c
		where
			h.conf_object_id is null and
			h.project_id = p.project_id and
			tree_root_key(p.tree_sortkey) = main_p.tree_sortkey and
			main_p.company_id = c.company_id
			and main_p.project_status_id not in ([im_project_status_deleted])
			and h.day >= to_timestamp(:start_date, 'YYYY-MM-DD')
			and h.day < to_timestamp(:end_date, 'YYYY-MM-DD')
			$where_clause
		group by
			h.day,
			h.user_id,
			main_p.project_id,
			main_p.project_name,
			main_p.project_lead_id,
			c.company_id,
			c.company_name			
		) t
	order by
		user_name,
		day_month,
		company_name,
		main_project_name,
		day
"

# Global header/footer
set header0 [list [_ intranet-core.User] [_ intranet-core.Month] [_ intranet-core.Customer] [_ intranet-core.Project_Name] [_ intranet-core.Project_Manager] [_ intranet-core.Date] [_ intranet-timesheet2.Hours]]
set footer0 {}

set report_def [list \
	group_by user_id \
	header {
		"\#colspan=99 <a href=$base_url&member_id=$user_id&level_of_detail=3 target=_blank><img src=/intranet/images/plus_9.gif border=0></a> <b><a href=$user_url$user_id>$user_name</a></b>"
	} \
	content [list \
		group_by day_month \
		header {
			""
			"#colspan=98 $day_month"
		} \
		content [list \
			header {
				""
				"$day_month"
				"<a href=$company_url$company_id>$company_name</a>"
				"<a href=$project_url$main_project_id>$main_project_name</a>"
				"<a href=$user_url$main_project_lead_id>$main_project_lead_name</a>"
				"$day_pretty"
				"#align=right $hours_pretty"
			} \
			content [list] \
		]\
		footer {"" "" "" "" "" "" "#align=right <i>$hours_monthly_sum_pretty</i>"} \
	] \
	footer {"" "" "" "" "" "" "#align=right <b>$hours_subtotal_pretty</b>"} \
]


# ------------------------------------------------------------
# Start Formatting the HTML Page Contents

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format $output_format -report_name "unsubmitted-hours"

switch $output_format {
    html {
	ns_write "
	[im_header $page_title]
	[im_navbar]
	<form>
	<table border=0 cellspacing=1 cellpadding=1>
	<tr valign=top><td>
		<table border=0 cellspacing=1 cellpadding=1>
		<tr>
	          <td class=form-label>[lang::message::lookup "" intranet-reporting.Level_of_Detail "Level of Detail"]</td>
		  <td class=form-widget>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>[_ intranet-core.User]</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -include_empty_name [_ intranet-core.--_Please_select_--] member_id $member_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>[lang::message::lookup "" intranet-core.Start_Date "Start Date"]</td>
		  <td class=form-widget>
		    <input type=textfield name=start_date value=$start_date>
		  </td>
		</tr>
		<tr>
		  <td class=form-label>[lang::message::lookup "" intranet-core.End_Date "End Date"]</td>
		  <td class=form-widget>
		    <input type=textfield name=end_date value=$end_date>
		  </td>
		</tr>
		<tr>
		  <td class=form-label>[_ intranet-core.Customer]</td>
		  <td class=form-widget>
		    [im_company_select company_id $company_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>[_ intranet-core.Project_Manager]</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -include_empty_name [_ intranet-core.--_Please_select_--] project_lead_id $project_lead_id]
		  </td>
		</tr>
                <tr>
                  <td class=form-label>[_ intranet-reporting.Format]</td>
                  <td class=form-widget>
                    [im_report_output_format_select output_format "" $output_format]
                  </td>
                </tr>
                <tr>
                  <td class=form-label><nobr>[_ intranet-reporting.Number_Format]</nobr></td>
                  <td class=form-widget>
                    [im_report_number_locale_select number_locale $number_locale]
                  </td>
                </tr>
                <tr>
		  <td class=form-label></td>
		  <td class=form-widget><input type=submit></td>
		</tr>
		</table>
	</td><td>
		<table border=0 cellspacing=1 cellpadding=1>
		</table>
	</td></tr>
	</table>
	</form>
	<table border=0 cellspacing=1 cellpadding=1>\n"
    }
}


im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"


set footer_array_list [list]
set last_value_list [list]
set class "rowodd"
db_foreach sql $sql {

    set hours_pretty [im_report_format_number $hours $output_format $number_locale]

    im_report_display_footer \
	-output_format $output_format \
	-group_def $report_def \
	-footer_array_list $footer_array_list \
	-last_value_array_list $last_value_list \
	-level_of_detail $level_of_detail \
	-row_class $class \
	-cell_class $class
    
    im_report_update_counters -counters $counters

    set hours_subtotal_pretty [im_report_format_number $hours_subtotal $output_format $number_locale]
    set hours_monthly_sum_pretty [im_report_format_number $hours_monthly_sum $output_format $number_locale]
    
    set last_value_list [im_report_render_header \
			     -output_format $output_format \
			     -group_def $report_def \
			     -last_value_array_list $last_value_list \
			     -level_of_detail $level_of_detail \
			     -row_class $class \
			     -cell_class $class
			]
    
    set footer_array_list [im_report_render_footer \
			       -output_format $output_format \
			       -group_def $report_def \
			       -last_value_array_list $last_value_list \
			       -level_of_detail $level_of_detail \
			       -row_class $class \
			       -cell_class $class
			  ]
}

im_report_display_footer \
    -output_format $output_format \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -level_of_detail $level_of_detail \
    -display_all_footers_p 1 \
    -row_class $class \
    -cell_class $class

im_report_render_row \
    -output_format $output_format \
    -row $footer0 \
    -row_class $class \
    -cell_class $class


# Write out the HTMl to close the main report table
# and write out the page footer.
#
switch $output_format {
    html { ns_write "</table>\n[im_footer]\n"}
}
