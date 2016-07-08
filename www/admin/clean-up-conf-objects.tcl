# /packages/intranet-timesheet2-workflow/www/admin/clean-up-conf-objects.tcl
#
# Copyright (C) 2003-2016 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/en/project-open-license for details.


ad_page_contract {
    Admin page for intranet-timesheet2-workflow
    @author klaus.hofeditz@project-open.com
} {
    { return_url "/intranet-timesheet2-workflow/admin/" }
}

set user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-timesheet2-workflow.CleanupConfigurationObjects "Clean up configuration objects"]

if { [im_is_user_site_wide_or_intranet_admin $user_id] } {

	# set im_hours::conf_object_id to NULL in case there's no WF case
	db_dml set_im_hours_conf_object_id "update im_hours set conf_object_id = null where conf_object_id not in ( select object_id from wf_cases )"

	# remove from im_timesheet_conf_objects if no wf_case 
	db_dml remove_from_im_timesheet_conf_objects "delete from im_timesheet_conf_objects where conf_id not in ( select distinct object_id from wf_cases )"

	util_user_message -message "Config Objects have been cleaned up."

	ad_returnredirect $return_url

} else {
	ad_return_complaint xx "You are not allowed to perform this action. Please contact your SysAdmin"
}

