$(function() {
  if (!$("section#uploading").length) { return; }

  var dropStatusLink = window.location.toString()
                         .split('?')[0]
                         .split('#')[0] + "/status";
  (function() {
    var check = arguments.callee;
    $.ajax({ url: dropStatusLink })
       .always(function(data, status, xhr) {
         if (xhr.status == 204) {
           window.setTimeout(check, 2000);
         } else {
           window.location.reload();
         }
       });
  }());
});
