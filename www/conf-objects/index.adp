<!-- packages/intranet-notes/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context_bar;literal@</property>
<property name="main_navbar_label">notes</property>
<property name="left_navbar">@left_navbar_html;literal@</property>

<!-- Show calendar on start- and end-date -->
<script type="text/javascript" <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>
window.addEventListener('load', function() { 
     document.getElementById('list_check_all').addEventListener('click', function() { acs_ListCheckAll('confs_list', this.checked) });
     document.getElementById('filter_start_date_calendar').addEventListener('click', function() { showCalendar('filter_start_date_calendar', 'y-m-d'); });
//     document.getElementById('end_date_calendar').addEventListener('click', function() { showCalendar('end_date', 'y-m-d'); });
});
</script>

<table width="100%">
<tr><td>
<listtemplate name="@list_id@"></listtemplate>
</td></tr>
</table>
<br>

