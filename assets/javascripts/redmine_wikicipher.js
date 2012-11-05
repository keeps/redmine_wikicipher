document.observe('click', function(event) {

	try{

  var switchesSelector = '.wikicipher_show,.wikicipher_hide';
  var contentSelector = '.wikicipher_content';

  var switcher = event.findElement(switchesSelector);
  if (switcher) {
    var encryptTagEl = switcher.parentNode;
	
    $$('.wikicipher_content').each(function(val,i) {
	var original = val.innerHTML;
	val.innerHTML=sjcl.decrypt("password", original);

    });
     $$('.wikicipher').each(function(val,i) {
	var selector = switchesSelector + ',' + contentSelector;
    Selector.matchElements(val.childElements(), selector).map(Element.toggle);
    Event.stop(event);

    });
  }
}catch(e){
alert(e);
}});

