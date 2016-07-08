<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="main_navbar_label">workflow</property>

<h1>Admin</h1>
<p>This site is not linked, so we assume you know what you do. Otherwise do not use any of the links below.</p>
<ul>
<li>
		<a href="/intranet-timesheet2-workflow/admin/clean-up-conf-objects">Clean up TS Configuration Objects</a><br/>
		<p>Cleans up 'configuration objects' in case WF cases have been deleted from the system.</p>
		<ol>
			<li>Removes conf_object_id from im_hours if no wf_case exists.</li>
			<li>Deletes configuration objects from im_timesheet_conf_objects with no entry in wf_case</li>
		</ol>
</li>
</ul>
