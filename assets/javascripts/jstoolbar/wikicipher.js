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
	var isWiki = "/Wiki/edit";
	if (warn.length>0){
		document.getElementsByClassName('jstb_wikicipher')[0].hide();
	}
	if(window.location.pathname.indexOf(isWiki, window.location.pathname.length - isWiki.length) !== -1){
		// nothing to do...
	}else{
		//hide wikicipher toolbar buttons
		var elems = document.getElementsByClassName('jstb_wikicipher');
		for(var i = 0; i != elems.length; ++i){
			elems[i].style.visibility = "hidden";
		}
	}
};
