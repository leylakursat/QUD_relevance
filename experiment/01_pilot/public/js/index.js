function make_slides(f) {
  var   slides = {};

  slides.bot = slide({
    name : "bot",
    start: function() {
      $('.err1').hide();
      $('.err2').hide();
      $('.disq').hide();
      exp.speaker = _.shuffle(["James", "John", "Robert", "Michael", "William", "David", "Richard", "Joseph", "Thomas", "Charles"])[0];
      exp.listener = _.shuffle(["Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan", "Jessica", "Sarah", "Margaret"])[0];
      exp.lives = 0;
      var story = exp.speaker + ' says to ' + exp.listener + ': "It\'s a beautiful day, isn\'t it?"'
      var question = 'Who does ' + exp.speaker + ' talk to?';
      document.getElementById("s").innerHTML = story;
      document.getElementById("q").innerHTML = question;
    },
    button : function() {
      exp.text_input = document.getElementById("text_box").value;
      var lower = exp.listener.toLowerCase();
      var upper = exp.listener.toUpperCase();

      if ((exp.lives < 3) && ((exp.text_input == exp.listener)|(exp.text_input == lower) | (exp.text_input== upper))){
        exp.data_trials.push({
          "slide_number": exp.phase,
          "slide_type" : "bot_check",
          "image" : exp.listener,
          "audio" : "",
          "response" : [0,exp.text_input]
        });
        exp.go();
      }
      else {
        exp.data_trials.push({
          "slide_number": exp.phase,
          "slide_type" : "bot_check",
          "image" : exp.listener,
          "audio" : "",
          "response" : [0,exp.text_input]
        });
        if (exp.lives == 0){
          $('.err1').show();
        }if (exp.lives == 1){
          $('.err1').hide();
          $('.err2').show();
        }if (exp.lives == 2){
          $('.err2').hide();
          $('.disq').show();
          $('.button').hide();
        }
        exp.lives++;
      } 
    },
  });

  slides.i0 = slide({
    name : "i0",
    start: function() {
    exp.startT = Date.now();
    }
  });

   slides.check = slide({
    name : "check",
    start: function() {
      $('.err').hide();
      $('.question').hide();
          document.getElementById("audio_check").play();
          setTimeout(function(){
            $('.question').show();
          },1500);
    },
    button : function() {
      this.radio  = $("input[name='number']:checked").val();
      if (this.radio == "Four") {
        this.log_responses();
        exp.go();
      } 
      else{
        $('.err').show();
        this.log_responses();
      }
    },
    log_responses : function() {
      exp.data_trials.push({
          "slide_number": exp.phase,
          "slide_type" : "audio_check",
          "image" : "",
          "audio" : "",
          "response" : [0,this.radio]
      });
    }
  });

  slides.instructions = slide({
    name : "instructions",
    start: function(){
      $('.tut_key_instructions').hide();
      $('.tut_initial_gumball').hide();
      $('.tut_final_gumball').hide();
      $('.tut_final2_gumball').hide();
      $('.tut_agreed').hide();
      $('.tut_disagreed').hide();
      $('.tut_warning').hide();
      $('.comprehension').hide();
      $('.err_wrong').hide();

      document.onkeydown = checkKey;
      function checkKey(e) {
        e = e || window.event;
        if (($('.tut_instructions').is(":visible")) && (e.keyCode == 32)) {
          e = 0;
          $('.tut_instructions').hide();
          $('.tut_key_instructions').show();
        }
        if (($('.tut_key_instructions').is(":visible")) && (e.keyCode == 32)) {
          $('.tut_key_instructions').hide();
          $('.tut_initial_gumball').show();
          setTimeout(function(){
            $('.tut_initial_gumball').hide();
            $('.tut_final_gumball').show();
            document.getElementById("tut_kaching").play();
            $('.tut_pressyes').hide();
            setTimeout(function(){
              document.getElementById("tut_stim").play();
              setTimeout(function(){
                $('.tut_pressyes').show();
              },1000)
            },1000)
          },2000)
        }
        if (($('.tut_final_gumball').is(":visible")) && (e.keyCode == 70)) {
          alert("You pressed the NO key.");
        }
        if (($('.tut_final_gumball').is(":visible")) && (e.keyCode == 74)) {
          $('.tut_final_gumball').hide();
          $('.tut_agreed').show();
          document.getElementById("tut_stim").pause();
          document.getElementById("tut_stim").currentTime = 0;
        }
        if (($('.tut_agreed').is(":visible")) && (e.keyCode == 32)) {
          $('.tut_agreed').hide();
          $('.tut_initial_gumball').show();
          setTimeout(function(){
            $('.tut_initial_gumball').hide();
            $('.tut_final2_gumball').show();
            document.getElementById("tut_kaching").play();
            $('.tut_pressno').hide();
            setTimeout(function(){
              document.getElementById("tut_stim2").play();
              setTimeout(function(){
                $('.tut_pressno').show();
              },1000)
            },1000)
          },2000)
        }
        if (($('.tut_final2_gumball').is(":visible")) && (e.keyCode == 74)) {
          alert("You pressed the YES key.");
        }
        if (($('.tut_final2_gumball').is(":visible")) && (e.keyCode == 70)) {
          $('.tut_final2_gumball').hide();
          $('.tut_disagreed').show();
          document.getElementById("tut_stim2").pause();
          document.getElementById("tut_stim2").currentTime = 0;
        }
        if (($('.tut_disagreed').is(":visible")) && (e.keyCode == 32)) {
          e = 0;
          $('.tut_disagreed').hide();
          $('.tut_warning').show();
        }
        if (($('.tut_warning').is(":visible")) && (e.keyCode == 32)) {
          e = 0;
          $('.tut_warning').hide();
          $('.comprehension').show();
          $('.err_empty').hide();
          $("input[name='fired']:checked").val = undefined;
        }
        if (($('.comprehension').is(":visible")) && (e.keyCode == 32)) {
          e = 0;
          this.radio = $("input[name='fired']:checked").val();
          if (this.radio == undefined) {
            $('.err_empty').show();
          }
          if(this.radio == "Empty"){
            // not great, this.log_response(); - out of scope
            exp.data_trials.push({
              "slide_number": exp.phase,
              "slide_type" : "comprehension_check_1",
              "image" : "",
              "audio" : "",
              "response" : [0,this.radio]
            });
            exp.go();  
          }
          if ((this.radio == "Jam")| (this.radio == "Explode")| (this.radio == "Silent")){
            $('.comprehension').hide();
            $('.err_wrong').show();
            $('input[name="fired"]').prop('checked', false);
            exp.data_trials.push({
              "slide_number": exp.phase,
              "slide_type" : "comprehension_check_1",
              "image" : "",
              "audio" : "",
              "response" : [0,this.radio]
            });
          }
        }
        if (($('.err_wrong').is(":visible")) && (e.keyCode == 32)) {
            $('.err_wrong').hide();
            $('.tut_instructions').show();
        }
      }
    },
  });
  
  slides.before_practice = slide({
    name : "before_practice",
    start : function() {
      document.onkeydown = checkKey;
      function checkKey(e) {
        e = e || window.event;
        if (e.keyCode == 32) 
          exp.go();
      }
    }
  });

  slides.practice = slide({
    name : "practice",
    present: exp.practice, 

    present_handle : function(stim) {                                                         
      exp.practicestartTime = 0;
      this.stim = stim;

      $('.final_gumball').hide();
      $('.transition').hide();
      $('.initial_gumball').show();

      var initial_image = '<img src="img/initial.jpg" style="height:500px" class="center">';
      $(".initial_image").html(initial_image);
      var version = Math.floor(Math.random() * 3) + 1;
      var final_image = '<img src="img/'+stim.image+'_'+version+'.jpg" style="height:500px" class="center">';
      $(".final_image").html(final_image);
      var aud = document.getElementById("stim");
      aud.src = "audio/"+stim.audio;
      aud.load();
 
      setTimeout(function(){
        $('.initial_gumball').hide();
        document.getElementById("kaching").play();
        $('.final_gumball').show();
        setTimeout(function(){
          aud.play(); 
          exp.practicestartTime = Date.now();
        },1000)
      },2000)
      
      document.onkeydown = checkKey;
      function checkKey(e) {
        e = e || window.event;
        if (($('.final_gumball').is(":visible")) && (e.keyCode == 70 || e.keyCode == 74)) {
          exp.responseTime = Date.now()-exp.practicestartTime;
          if(e.keyCode == 74)
            exp.keyCode = "Yes";
          if(e.keyCode == 70)
            exp.keyCode = "No";   
          $('.final_gumball').hide();
          $('.transition').show();
          aud.pause();
          aud.currentTime = 0;
        } 
        if (($('.warning_all').is(":visible")) && (e.keyCode == 32)) {
          e.keyCode =0;
          $('.warning_all').hide();
          $('.transition').show();
        }
        if (($('.transition').is(":visible")) && (e.keyCode == 32)) {
          _s.button();
        }
      }
    },

    button : function() {
      this.log_responses();
      _stream.apply(this);
    },

    log_responses : function() {
      exp.data_trials.push({
          "slide_number": exp.phase,
          "slide_type" : "practice_trial",
          "image" : this.stim.image,
          "audio" : this.stim.audio,
          "response" : [exp.responseTime, exp.keyCode]
      });
    }
  });

  slides.before_trial = slide({
    name : "before_trial",
    start : function() {
      document.onkeydown = checkKey;
      function checkKey(e) {
        e = e || window.event;
        if (e.keyCode == 32) 
          exp.go();
      }
    }
  });

  slides.trial1 = slide({
    name : "trial1",
    present: exp.stims,
    present_handle : function(stim) {
      exp.test_start = Date.now();                                                                  // TESTING
      exp.startTime = 0;
      this.stim = stim;

      $('.final_gumball').hide();
      $('.transition').hide();
      $('.initial_gumball').show()

      var initial_image = '<img src="img/initial.jpg" style="height:500px" class="center">';
      $(".initial_image").html(initial_image);
      var version = Math.floor(Math.random() * 3) + 1;
      var final_image = '<img src="img/'+stim.image+'_'+version+'.jpg" style="height:500px" class="center">';
      $(".final_image").html(final_image);
      var aud = document.getElementById("stim");
      aud.src = "audio/"+stim.audio;
      aud.load();
      
      console.log("BEGINNING OF TRIAL, TIME: " + (Date.now()-exp.test_start));                       // TESTING
      console.log("image: "+stim.image);                                                             // TESTING
      console.log("audio: "+stim.audio);                                                             // TESTING
  
      setTimeout(function(){
        $('.initial_gumball').hide();
        document.getElementById("kaching").play();
        $('.final_gumball').show();
        console.log("IMAGE CHANGED, TIME: " + (Date.now()-exp.test_start));                          // TESTING
        setTimeout(function(){
          aud.play(); 
          console.log("AUDIO PLAYED, TIME: " + (Date.now()-exp.test_start));                         // TESTING
          exp.startTime = Date.now();
          console.log("TIMER STARTED, TIME: " + (Date.now()-exp.test_start));                        // TESTING
        },1000)
      },2000)
      
      document.onkeydown = checkKey;
      function checkKey(e) {
        e = e || window.event;
        if (($('.final_gumball').is(":visible")) && (e.keyCode == 70 || e.keyCode == 74)) {
          exp.responseTime = Date.now()-exp.startTime;
          console.log("TIMER ENDED, TIME: " + (Date.now()-exp.test_start));
          console.log("RESPONSE TIME: "+  exp.responseTime);                                         // TESTING
          if(e.keyCode == 74)
            exp.keyCode = "Yes";
          if(e.keyCode == 70)
            exp.keyCode = "No";   
          $('.final_gumball').hide();
          $('.transition').show();
          aud.pause();
          aud.currentTime = 0;
        } 
        if (($('.transition').is(":visible")) && (e.keyCode == 32)) {
          _s.button();
        }
      }
    },
    button : function() {
      this.log_responses();
      _stream.apply(this);
    },
    log_responses : function() {
      exp.data_trials.push({
          "slide_number": exp.phase,
          "slide_type" : "critical_trial_1",
          "image" : this.stim.image,
          "audio" : this.stim.audio,
          "response" : [exp.responseTime, exp.keyCode]
      });
    }
  });

  slides.comprehension = slide({
    name : "comprehension",
    start : function() {
      $('.err_empty').hide();
      $('.err_show').hide();
      $('.quiz').show();
      document.onkeydown = checkKey;
      function checkKey(e) {
        e = e || window.event;
        if (($('.quiz').is(":visible"))&(e.keyCode == 32)) {
          this.radio = $("input[name='fired']:checked").val();
          if (this.radio == undefined) {
            $('.err_empty').show();
          }
          if(this.radio == "Empty") {
            exp.data_trials.push({
              "slide_number": exp.phase,
              "slide_type" : "comprehension_check_2",
              "image" : "",
              "audio" : "",
              "response" : [0,this.radio]
              });
            exp.go();
          }
          if ((this.radio == "Jam")| (this.radio == "Explode")| (this.radio == "Silent")){
            $('.quiz').hide();
            $('.err_wrong').show();
            $('input[name="fired"]').prop('checked', false);
            exp.data_trials.push({
              "slide_number": exp.phase,
              "slide_type" : "comprehension_check_2",
              "image" : "",
              "audio" : "",
              "response" : [0,this.radio]
              });
          }
        }
        if (($('.err_wrong').is(":visible"))&(e.keyCode == 32)){
            $('.err_empty').hide();
            $('.quiz').show();
        } 
      }
    }
  });

    slides.trial2 = slide({
    name : "trial2",
    present: exp.stims2, //every element in exp.stims is passed to present_handle one by one as 'stim'
    present_handle : function(stim) {
      exp.test_start = Date.now();                                                                  // TESTING
      exp.startTime = 0;
      this.stim = stim;

      $('.final_gumball').hide();
      $('.transition').hide();
      $('.initial_gumball').show()

      var initial_image = '<img src="img/initial.jpg" style="height:500px" class="center">';
      $(".initial_image").html(initial_image);
      var version = Math.floor(Math.random() * 3) + 1;
      var final_image = '<img src="img/'+stim.image+'_'+version+'.jpg" style="height:500px" class="center">';
      $(".final_image").html(final_image);
      var aud = document.getElementById("stim");
      aud.src = "audio/"+stim.audio;
      aud.load();
      
      console.log("BEGINNING OF TRIAL, TIME: " + (Date.now()-exp.test_start));                       // TESTING
      console.log("image: "+stim.image);                                                             // TESTING
      console.log("audio: "+stim.audio);                                                             // TESTING
  
      setTimeout(function(){
        $('.initial_gumball').hide();
        document.getElementById("kaching").play();
        $('.final_gumball').show();
        console.log("IMAGE CHANGED, TIME: " + (Date.now()-exp.test_start));                          // TESTING
        setTimeout(function(){
          aud.play(); 
          console.log("AUDIO PLAYED, TIME: " + (Date.now()-exp.test_start));                         // TESTING
          exp.startTime = Date.now();
          console.log("TIMER STARTED, TIME: " + (Date.now()-exp.test_start));                        // TESTING
        },1000)
      },2000)
      
      document.onkeydown = checkKey;
      function checkKey(e) {
        e = e || window.event;
        if (($('.final_gumball').is(":visible")) && (e.keyCode == 70 || e.keyCode == 74)) {
          exp.responseTime = Date.now()-exp.startTime;
          console.log("TIMER ENDED, TIME: " + (Date.now()-exp.test_start));
          console.log("RESPONSE TIME: "+  exp.responseTime);                                         // TESTING
          if(e.keyCode == 74)
            exp.keyCode = "Yes";
          if(e.keyCode == 70)
            exp.keyCode = "No";   
          $('.final_gumball').hide();
          $('.transition').show();
          aud.pause();
          aud.currentTime = 0;
        } 
        if (($('.transition').is(":visible")) && (e.keyCode == 32)) {
          _s.button();
        }
      }
    },
    button : function() {
      this.log_responses();
      _stream.apply(this);
    },
    log_responses : function() {
      exp.data_trials.push({
          "slide_number": exp.phase,
          "slide_type" : "critical_trial_2",
          "image" : this.stim.image,
          "audio" : this.stim.audio,
          "response" : [exp.responseTime, exp.keyCode]
      });
    }
  });

  slides.subj_info =  slide({
    name : "subj_info",
    submit : function(e){
      exp.subj_data = {
        language : $("#language").val(),
        enjoyment : $("#enjoyment").val(),
        asses : $('input[name="assess"]:checked').val(),
        age : $("#age").val(),
        gender : $("#gender").val(),
        education : $("#education").val(),
        comments : $("#comments").val(),
        problems: $("#problems").val(),
        fairprice: $("#fairprice").val()
      };
      exp.go();
    }
  });

  slides.thanks = slide({
    name : "thanks",
    start : function() {
      exp.data= {
          "trials" : exp.data_trials,
          "catch_trials" : exp.catch_trials,
          "system" : exp.system,
          "condition" : exp.condition,
          "subject_information" : exp.subj_data,
          "time_in_minutes" : (Date.now() - exp.startT)/60000
      };
      setTimeout(function() {turk.submit(exp.data);}, 1000);
    }
  });

  return slides;
}

/// init ///
function init() {
  exp.trials = [];
  exp.catch_trials = [];

  exp.condition = "relevant condition(empty context)";

quarter_1 =[
  {sentence: "You got some gumballs.", image: "0", audio: "some.wav"},
  {sentence: "You got some gumballs.", image: "8", audio: "some.wav"},
  {sentence: "You got some gumballs.", image: "13", audio: "some.wav" },
  {sentence: "You got some gumballs.", image: "13", audio: "some.wav" },
  {sentence: "You got all of the gumballs.", image: "2", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "5", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "13", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "13", audio: "all.wav"},
  {sentence: "You got none of the gumballs.", image: "0", audio: "none.wav"},
  {sentence: "You got none of the gumballs.", image: "8", audio: "none.wav"},
  {sentence: "You got five of the gumballs.", image: "0", audio: "five.wav"},
  {sentence: "You got two of the gumballs.", image: "2", audio: "two.wav"},
  {sentence: "You got two of the gumballs.", image: "2", audio: "two.wav"},
  {sentence: "You got four of the gumballs.", image: "5", audio: "four.wav"},
  {sentence: "You got eight of the gumballs.", image: "8", audio: "eight.wav"},
  {sentence: "You got thirteen of the gumballs.", image: "8", audio: "thirteen.wav"},
  {sentence: "You got eleven of the gumballs.", image: "8", audio: "eleven.wav"},
  {sentence: "You got eight of the gumballs.", image: "13", audio: "eight.wav"}
];
quarter_2 = [
  {sentence: "You got some gumballs.", image: "0", audio: "some.wav"},
  {sentence: "You got some gumballs. ", image: "5", audio: "some.wav"},
  {sentence: "You got some gumballs.", image: "13", audio: "some.wav"},
  {sentence: "You got some gumballs.", image: "13", audio: "some.wav"},
  {sentence: "You got all of the gumballs.", image: "0", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "11", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "13", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "13", audio: "all.wav"},
  {sentence: "You got none of the gumballs.", image: "0", audio: "none.wav"},
  {sentence: "You got none of the gumballs.", image: "0", audio: "none.wav"},
  {sentence: "You got eleven of the gumballs.", image: "0", audio: "eleven.wav"},
  {sentence: "You got two of the gumballs. ", image: "2", audio: "two.wav"},
  {sentence: "You got two of the gumballs.", image: "2", audio: "two.wav"},
  {sentence: "You got five of the gumballs. ", image: "5", audio: "five.wav"},
  {sentence: "You got ten of the gumballs. ", image: "5", audio: "ten.wav"},
  {sentence: "You got eight of the gumballs.", image: "8", audio: "eight.wav"},
  {sentence: "You got eleven of the gumballs.", image: "11", audio: "eleven.wav"},
  {sentence: "You got seven of the gumballs.", image: "11", audio: "seven.wav"}
];
quarter_3 = [
  {sentence: "You got some gumballs.", image: "0", audio: "some.wav"},
  {sentence: "You got some gumballs.", image: "2", audio: "some.wav"},
  {sentence: "You got some gumballs.", image: "13", audio: "some.wav"},
  {sentence: "You got some gumballs.", image: "13", audio: "some.wav"},
  {sentence: "You got all of the gumballs.", image: "5", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "8", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "13", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "13", audio: "all.wav"},
  {sentence: "You got none of the gumballs.", image: "0", audio: "none.wav"},
  {sentence: "You got none of the gumballs.", image: "13", audio: "none.wav"},
  {sentence: "You got three of the gumballs.", image: "0", audio: "three.wav"},
  {sentence: "You got two of the gumballs.", image: "2", audio: "two.wav"},
  {sentence: "You got five of the gumballs.", image: "5", audio: "five.wav"},
  {sentence: "You got two of the gumballs.", image: "5", audio: "two.wav"},
  {sentence: "You got eight of the gumballs.", image: "8", audio: "eight.wav"},
  {sentence: "You got eight of the gumballs.", image: "8", audio: "eight.wav"},
  {sentence: "You got one of the gumballs.", image: "11", audio: "one.wav"},
  {sentence: "You got ten of the gumballs.", image: "13", audio: "ten.wav"}
];
quarter_4 = [
  {sentence: "You got some gumballs.", image: "0", audio: "some.wav"},
  {sentence: "You got some gumballs.", image: "11", audio: "some.wav"},
  {sentence: "You got some gumballs.", image: "13", audio: "some.wav"},
  {sentence: "You got some gumballs.", image: "13", audio: "some.wav"},
  {sentence: "You got all of the gumballs. ", image: "0", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "11", audio: "all.wav"},
  {sentence: "You got all of the gumballs.", image: "13", audio: "all.wav"},
  {sentence: "You got all of the gumballs. ", image: "13", audio: "all.wav"},
  {sentence: "You got none of the gumballs.", image: "0", audio: "none.wav"},
  {sentence: "You got none of the gumballs.", image: "2", audio: "none.wav"},
  {sentence: "You got two of the gumballs.", image: "2", audio: "two.wav"},
  {sentence: "You got twelve of the gumballs.", image: "2", audio: "twelve.wav"},
  {sentence: "You got five of the gumballs.", image: "5", audio: "five.wav"},
  {sentence: "You got nine of the gumballs.", image: "5", audio: "nine.wav"},
  {sentence: "You got eight of the gumballs.", image: "8", audio: "eight.wav"},
  {sentence: "You got two of the gumballs.", image: "8", audio: "two.wav"},
  {sentence: "You got eleven of the gumballs.", image: "11", audio: "eleven.wav"},
  {sentence: "You got five of the gumballs.", image: "13", audio: "five.wav"}
];

  //exp.stims =  _.shuffle(quarter_1); 

  exp.stims = _.shuffle(quarter_1).concat(_.shuffle(quarter_2));
  exp.stims2 = _.shuffle(quarter_3).concat(_.shuffle(quarter_4));
  
  exp.practice = [
    {sentence: "You got none of the gumballs.", image: "13", audio: "none.wav"},
    {sentence: "You got all of the gumballs.", image: "13", audio: "all.wav"},
    {sentence: "You got all of the gumballs.", image: "0", audio: "all.wav"},
    {sentence: "You got none of the gumballs.", image: "0", audio: "none.wav"}
  ]

  //exp.stims = deneme;

  console.log(exp.stims.length);
   console.log(exp.stims2.length);

  exp.system = {
      Browser : BrowserDetect.browser,
      OS : BrowserDetect.OS,
      screenH: screen.height,
      screenUH: exp.height,
      screenW: screen.width,
      screenUW: exp.width
    };

  //blocks of the experiment:
  exp.structure=["bot", "i0", "check","instructions", "before_practice", "practice", "before_trial", "trial1", "comprehension", "trial2", 'subj_info', 'thanks'];

  exp.data_trials = [];
  //make corresponding slides:
  exp.slides = make_slides(exp);

  exp.nQs = utils.get_exp_length(); //this does not work if there are stacks of stims (but does work for an experiment with this structure)
                    //relies on structure and slides being defined

  $('.slide').hide(); //hide everything

  //make sure turkers have accepted HIT (or you're not in mturk)
  $("#start_button").click(function() {
    if (turk.previewMode) {
      $("#mustaccept").show();
    } else {
      $("#start_button").click(function() {$("#mustaccept").show();});
      exp.go();
    }
  });

  exp.go(); //show first slide
}
