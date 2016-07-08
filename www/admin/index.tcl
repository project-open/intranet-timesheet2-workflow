# /packages/intranet-timesheet2-workflow/www/admin/index.tcl
#
# Copyright (C) 2003-2016 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/en/project-open-license for details.


ad_page_contract {
    Admin page for intranet-timesheet2-workflow

    @author klaus.hofeditz@project-open.com

} {

}

set user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-timesheet2-workflow.AdminHome "Admin TS Confirmation WF"]

if { ![im_is_user_site_wide_or_intranet_admin $user_id] } { ad_return_complaint xx "You need to be a SysAdmin to access this page." }
