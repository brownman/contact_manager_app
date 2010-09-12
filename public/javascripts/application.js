document.observe('dom:loaded', function() {
  $('person_first_name').observe('keyup', function() {
    var value = this.value;
    $$('TABLE TR:not(:first)').each(function(el) {
      var name = el.childElements('TD')[0].innerHTML;
      if(name.match(value)) {
        el.show();
      } else {
        el.hide();
      }
    });    
  });
});