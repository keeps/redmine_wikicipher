// encrypt_tag



jsToolBar.prototype.elements.wikicipher = {
  type: 'button',
  title: 'Wikicipher tag',
  fn: {
    wiki: function() { this.encloseSelection('{{cipher}}', '{{cipher}}') }
  }
}

window.onload=function(){
	var warn = document.getElementsByClassName('flash warning');
	var wikiEdit = "/edit";
	var wiki = "wiki";
	if (warn.length>0){
		document.getElementsByClassName('jstb_wikicipher')[0].hide();
	}
};
