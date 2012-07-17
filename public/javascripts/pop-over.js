$(function() {
  $('.menu .trigger').click(function(e) {
    e.preventDefault();
    e.stopPropagation();
    $(this).toggleClass('is-active');
  });

  $('.menu .drop-down').click(function(e) {
    e.stopPropagation();
  });

  $(document).click(function(e) {
    if ($('.menu .drop-down').is(':visible')) {
      $('.menu .trigger').toggleClass('is-active');
    }
  });
});
