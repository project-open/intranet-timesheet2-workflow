# /packages/intranet-timesheet2-workflow/www/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# https://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@project-open.com
} {
    { object_id:integer 0}
    { filter_owner_id:integer ""}
    { filter_status_id:integer ""}
    { filter_type_id:integer ""}
    { filter_cost_center_id:integer ""}
    { filter_start_date ""}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [auth::require_login]
set current_user_id $user_id
set page_focus "im_header_form.keywords"
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set date_format "YYYY-MM-DD"
set object_name [db_string object_name "select acs_object__name(:object_id)" -default [lang::message::lookup "" intranet-core.Unassigned "Unassigned"]]
set page_title [_ intranet-timesheet2-workflow.Timesheet_Approval]
set context_bar [im_context_bar $page_title]
set return_url [im_url_with_query]
set current_url [ns_conn url]
set edit_project_all_p [im_permission $current_user_id "edit_projects_all"]


if {![im_permission $user_id "view_timesheet_conf_all"]} {
    set filter_owner_id $user_id
}




if {"" eq $filter_start_date} {
    set filter_start_date [db_string one_year "select (now() - '1 year'::interval)::date"]
}

    if {[catch {
        if { $filter_start_date != [clock format [clock scan $filter_start_date] -format %Y-%m-%d] } {
            ad_return_complaint 1 "<strong>[_ intranet-core.Start_Date]</strong> [lang::message::lookup "" intranet-core.IsNotaValidDate "is not a valid date"].<br>
            [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$filter_start_date'<br>"
        }
    } err_msg]} {
        ad_return_complaint 1 "<strong>[_ intranet-core.Start_Date]</strong> [lang::message::lookup "" intranet-core.DoesNotHaveRightFormat "doesn't have the right format"].<br>
        [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$filter_start_date'<br>
        [lang::message::lookup "" intranet-core.Expected_Format "Expected Format"]: 'YYYY-MM-DD'"
    }



# ---------------------------------------------------------------
# Admin Links
# ---------------------------------------------------------------

set admin_links ""
append admin_links " <li><a href=\"[export_vars -base new {object_id return_url}]\">[_ intranet-timesheet2-workflow.Add_a_new_Conf]</a>\n"
if {"" != $admin_links} { set admin_links "<ul>\n$admin_links</ul>\n" }

set bulk_actions_list "[list]"
#[im_permission $user_id "delete_expense"]
set delete_expense_p 1 
if {$delete_expense_p} {
    lappend bulk_actions_list "[_ intranet-timesheet2-workflow.Delete]" "delete" "[_ intranet-timesheet2-workflow.Remove_checked_items]"
}
#[im_permission $user_id "add_expense_bundle"]
set create_invoice_p 1
if {$create_invoice_p} {
}

# ---------------------------------------------------------------
# Expenses info
# ---------------------------------------------------------------

# Variables of this page to pass through the expenses_page

set export_var_list [list]

# define list object
set list_id "confs_list"


template::list::create \
    -name $list_id \
    -multirow conf_lines \
    -key conf_id \
    -has_checkboxes \
    -bulk_action_method GET \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	object_id
	return_url
    } \
    -row_pretty_plural "[_ intranet-timesheet2-workflow.Confs_Items]" \
    -elements {
	conf_chk {
	    label "<input id=list_check_all type=\"checkbox\" name=\"_dummy\" title=\"Check/uncheck all rows\">"
	    display_template {
		@conf_lines.conf_chk;noquote@
	    }
	}
	period {
	    label "[lang::message::lookup {} intranet-timesheet2-workflow.Period Period]"
	    link_url_eval {[export_vars -base "/intranet-timesheet2-workflow/conf-objects/new" {conf_id {form_mode display}}]}
	}
	project_name {
	    label "[_ intranet-timesheet2-workflow.Project]"
	    link_url_eval {[export_vars -base "/intranet/projects/view" {{project_id $conf_project_id}}]}
	}
        conf_user_name {
	    label "[_ intranet-timesheet2-workflow.Conf_User]"
	    link_url_eval "/intranet/users/view?user_id=$conf_user_id"
	}
        conf_status {
	    label "[lang::message::lookup {} intranet-timesheet2-workflow.Conf_Status Status]"
	}
    }


# Only show conf_items of projects that are controlled by the user
set project_permission_where "1=1"
if {![im_permission $current_user_id "view_projects_all"]} {
    set project_permission_where "
	p.project_id in (
		select	r.object_id_one
		from	acs_rels r
		where	r.object_id_two = :current_user_id
	)
    "
}



if { $filter_status_id ne "" && $filter_status_id > 0 } {
    lappend criteria "co.conf_status_id in ([join [im_sub_categories -include_disabled_p 1 $filter_status_id] ","])"
}
if { $filter_type_id ne "" && $filter_type_id != 0 } {
    lappend criteria "co.conf_type_id in ([join [im_sub_categories -include_disabled_p 1 $filter_type_id] ","])"
}
if {0 != $filter_owner_id && "" != $filter_owner_id} {
    lappend criteria "co.conf_user_id = :filter_owner_id"
}
if {"" != $filter_start_date} {
    lappend criteria "co.start_date >= :filter_start_date::timestamptz"
}
if {"" != $filter_cost_center_id} {
    set filter_cost_center_code [db_string cc_code "select cost_center_code from im_cost_centers where cost_center_id = :filter_cost_center_id" -default ""]
    lappend criteria "co.conf_user_id in (
		select	pe.person_id
		from	im_cost_centers cc,
			im_employees e,
			persons pe
		where	substring(cc.cost_center_code for (length(:filter_cost_center_code))) = :filter_cost_center_code and
			e.department_id = cc.cost_center_id and
			e.employee_id = pe.person_id
    )"
}

set where_clause [join $criteria " and\n            "]
if { $where_clause ne "" } {
    set where_clause " and $where_clause"
}


db_multirow -extend {conf_chk return_url period} conf_lines confs_lines "
	select	co.*,
		p.project_name,
		im_name_from_user_id(co.conf_user_id) as conf_user_name,
		im_category_from_id(co.conf_status_id) as conf_status,
		(select count(*) 
		from	acs_rels r,
			im_biz_object_members bom
		where	r.rel_id = bom.rel_id and
			bom.object_role_id in (1301,1302,1303,1309) and
			r.object_id_two = :current_user_id and 
			r.object_id_one = p.project_id
		) as write_p
	from	im_timesheet_conf_objects co
		LEFT OUTER JOIN im_projects p ON (co.conf_project_id = p.project_id)
	where	
		$project_permission_where
		$where_clause
" {
    set return_url [im_url_with_query]
    set conf_chk "<input type=\"checkbox\" name=\"conf_id\" value=\"$conf_id\" id=\"confs_list,$conf_id\">"
    if {!$edit_project_all_p && !$write_p} { set conf_chk "" }
    set period "$start_date - $end_date"
}






# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

set owner_options [util_memoize [list im_employee_options] 3600]
set cost_center_options [im_cost_center_options -include_empty 1]

set form_id "conf_filter"
set object_type "im_timesheet_conf_object"
set action_url "/intranet-timesheet2-workflow/conf-objects/index"
set form_mode "edit"

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export { order_by how_many view_name} \
    -form {
	{filter_start_date:text(text),optional {label "[_ intranet-timesheet2.Start_Date]"} {value "$filter_start_date"} {html {size 10}} {after_html {<input type="button" id=filter_start_date_calendar style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" >}}}
    	{filter_owner_id:text(select),optional {label "[lang::message::lookup {} intranet-confdb.Owner {Owner}]"} {options $owner_options }}
    	{filter_cost_center_id:text(select),optional {label "[lang::message::lookup {} intranet-confdb.Cost_Center {Cost Center}]"} {options $cost_center_options }}
	{filter_status_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-core.Conf_Item_Status {Status}]"} {custom {category_type "Intranet Conf Item Status" translate_p 1 package_key "intranet-confdb"}} }
    }

    im_dynfield::append_attributes_to_form \
        -object_type $object_type \
        -form_id $form_id \
        -object_id 0 \
	-advanced_filter_p 1

    # Set the form values from the HTTP form variable frame
    im_dynfield::set_form_values_from_http -form_id $form_id
    im_dynfield::set_local_form_vars_from_http -form_id $form_id

    array set extra_sql_array [im_dynfield::search_sql_criteria_from_form \
	-form_id $form_id \
	-object_type $object_type
    ]




# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

eval [template::adp_compile -string {<formtemplate id="conf_filter"></formtemplate>}]
set filter_html $__adp_output

set left_navbar_html "
    <div class='filter-block'>
      <div class='filter-title'>
	[lang::message::lookup "" intranet-confdb.Filter_Items "Filter Items"]
      </div>
      $filter_html
    </div>
    <hr>

    <div class='filter-block'>
      <div class='filter-title'>
        [_ intranet-core.Admin_Links]
      </div>
      $admin_links
    </div>
"
