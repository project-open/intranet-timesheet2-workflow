<!-- packages/intranet-notes/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->

<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context_bar;literal@</property>
<property name="main_navbar_label">notes</property>


<script type="text/javascript" <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>
window.addEventListener('load', function() { 
     document.getElementById('list_check_all').addEventListener('click', function() { acs_ListCheckAll('confs_list', this.checked) });
});
</script>

<table width="100%">
<tr><td>
<listtemplate name="@list_id@"></listtemplate>
</td></tr>
</table>
<br>

