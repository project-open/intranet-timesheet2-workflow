<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="main_navbar_label">timesheet</property>

<h2>@page_title@</h2>

<p>
<%= [lang::message::lookup "" intranet-timesheet2-workflow.Creating_workflow_for_all_hours_logged "Creating workflows for all hours logged between %start_date% - %end_date%."] %>
</p>
<br>

<ul>
@li_html;noquote@
</ul>
<br>&nbsp;<br>

<p>
<a href="@return_url@"
><%= [lang::message::lookup "" intranet-timesheet2-workflow.Return_to_previous_page "Return to previous page"] %></a>
</p>
<br>
