Box.Application.addModule('cabinet', function(context) {
  'use strict';
  var $context = $(context.getElement());

  function interaction_listener(bottle_div) {
    $(bottle_div).parents('.pill-container').toggleClass('active');
    var $set_id = bottle_div.next('input').attr('id');

    $.ajax({
      url: '/interactions',
      method: 'POST',
      dataType: "json",
      data: {medicine_id: $set_id},
      success: function(data) {
        var text = '';
        if (data['interactions_text']) {
          text = highlight_keywords(data.interactions, data.interactions_text)
        } else {
          text = 'There is no interaction information for this medicine.'
        }
        $('#interactions > p').html(text);
      }
    });
  }

  function delete_medicine(delete_elm) {
    $.ajax({
      url: '/destroy/' + $(delete_elm).attr('data-set-id'),
      method: 'DELETE',
      success: function(data) {
        redraw_shelf(data);
      }
    });
  }

  function redraw_shelf(html_data) {
    $context.html(html_data);
  }

  function highlight_keywords(keywords, text) {
    var html = ''
    $.each(keywords, function(key, values) {
      var reg = new RegExp(values.join('|'), 'gi');
      html = text.replace(reg, '<span class="' + key + '-highlight">$&</span>')
    });

    return html
  }

  function make_last_active() {
    var $last_med = $context.find('.pill-bottle').last();
    if ($last_med.length > 0) {
      interaction_listener($last_med);
    }
  }

  return {
    messages: ['refresh_shelves'],

    init: function() {
      make_last_active();
    },

    onmessage: function (name, data) {
      if (name == 'refresh_shelves') {
        redraw_shelf(data.html);
        make_last_active();
      }
    },

    onclick: function(event, element, elementType) {
      event.preventDefault();
      if ($(event.target).hasClass('pill-delete')) {
        delete_medicine(event.target);
      }
      else if ($(event.target).parents('.pill-bottle').length > 0) {
        interaction_listener($(event.target).parents('.pill-bottle'));
      }
    }
  }
});