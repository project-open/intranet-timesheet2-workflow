ad_library {

    Initialization for intranet-timesheet2-workflow module

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 16 January, 2014
    @cvs-id $Id$
}

# Check for users with unsubmitted hours and send out notification emails
set interval [parameter::get_from_package_key -package_key intranet-timesheet2-workflow -parameter "UnsubmittedHoursUserNotificationInterval" -default 0]
if {0 != $interval} {
    ad_schedule_proc -thread t $interval im_timesheet2_workflow_unsubmitted_hours_user_notification_sweeper
}

