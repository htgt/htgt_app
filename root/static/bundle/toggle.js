//Author:jc3 2008-03-11 toggle login box
Event.observe(window,'load',function(){
  if($('loginLink')){
    Event.observe('loginLink','click',function(event){
      if($('login_box')){
        if($('login_box').style.display=='none'){
          $('login_box').show();
          Form.focusFirstElement($('login_box').getElementsByTagName('form')[0]);
        }
        else{
          $('login_box').hide();
        }
        Event.stop(event)
      }
    });
  }
});

