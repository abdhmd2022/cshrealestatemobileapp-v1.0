import 'package:cshrealestatemobile/SalesDashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

class Login extends StatefulWidget {
  const Login({super.key, required this.title});
  final String title;

  @override
  State<Login> createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> {

  bool isVisibleLoginForm= true,_isLoading = false,isButtonDisabled = false;

  Color _buttonColor = appbar_color;

  final _formKey = GlobalKey<FormState>();

  final passwordController = TextEditingController();

  final emailController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscureText = true;

  bool remember_me = true;

  late String email, password;

  final requiredLength = 4; // the required length of the password

  void _onPasswordChanged() {
    // Check the length of the password
    if (passwordController.text.length < requiredLength) {
      // If the password is too short, update the button color to grey
      setState(() {
        _buttonColor = Colors.grey;
        isButtonDisabled = true;
      });
    }
    else
    {
      setState(() {
        _buttonColor = appbar_color;
        isButtonDisabled = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_onPasswordChanged);

    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: appbar_color,
          title: Text(widget.title,
          style: TextStyle(
            color: Colors.white
          ),),
        ),
        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            /*decoration:BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Color(0xFFD9FCF6),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter
              ),
            ),*/
            child:    SingleChildScrollView(
              child:  Column(
                  children: [
                    Container(
                        padding: EdgeInsets.only(top: 50,bottom: 30),
                        child: Icon(
                          Icons.real_estate_agent_outlined,
                          size: 120,
                        )
                    ),

                    Visibility(
                        visible: isVisibleLoginForm,
                        child:Container(
                            padding: EdgeInsets.only(left: 32,right: 32,top : 70),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 0, // Spread radius
                                    blurRadius: 20, // Blur radius
                                    offset: Offset(0, -10),
                                  ),
                                ],
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(50),
                                    topRight: Radius.circular(50)
                                )
                            ),
                            child:Form(
                                key: _formKey,
                                child: ListView(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    children: [
                                      Container(padding: EdgeInsets.only(top: 5),
                                        child: TextFormField(
                                          controller: emailController,
                                          focusNode: _emailFocusNode,
                                          decoration: InputDecoration(
                                            labelText: 'Email Address',
                                            filled: true,
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                              borderSide: BorderSide(
                                                color: Colors.black12,
                                              ),
                                            ),
                                            fillColor: Colors.white,
                                            labelStyle: TextStyle(
                                              color: Colors.black54, // Set the label text color to black
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: Colors.black),
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),

                                          validator: (value) {
                                            if (value == null || value.isEmpty)
                                            {
                                              return 'Please enter your email address';
                                            }
                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                                            {
                                              return 'Please enter a valid email address';
                                            }
                                            return null;
                                          },
                                          onSaved: (value) => email = value!,
                                        ),),

                                      SizedBox(height: 16.0),

                                      TextFormField(
                                        controller: passwordController,
                                        focusNode: _passwordFocusNode,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(5.0),
                                            borderSide: BorderSide(
                                              color: Colors.black12,
                                            ),
                                          ),

                                          suffixIcon: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _obscureText = !_obscureText;
                                              });
                                            },
                                            child: Icon(
                                              _obscureText ? Icons.visibility_off :  Icons.visibility,
                                            ),
                                          ),

                                          labelText: 'Password',
                                          filled: true,
                                          fillColor: Colors.white,
                                          labelStyle: TextStyle(
                                            color: Colors.black54, // Set the label text color to black
                                          ),

                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Colors.black),

                                          ),
                                        ),
                                        obscureText: _obscureText,

                                        validator: (value)
                                        {
                                          if (value == null || value.isEmpty)
                                          {
                                            return 'Please enter your password';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) => password = value!,
                                      ),

                                      SizedBox(height: 5), // Ad

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              // Handle "Forgot Password" tap event here
                                              setState(() {
                                                /*isVisibleLoginForm = false;*/

                                                /*resetemailController.text = usernameController.text;*/

                                                /*passwordController.clear();*/
                                                /*isVisibleResetPassForm = true;*/
                                              });
                                            },
                                            child: Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                color: Colors.black54,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.start,children: [

                                            Checkbox(
                                              value: remember_me,
                                              activeColor: appbar_color,
                                              checkColor: Colors.white, // Optional: sets the color of the check icon
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  remember_me = value!;
                                                });
                                              },
                                            ),

                                            Text(
                                              'Remember Me',
                                              style: TextStyle(fontSize: 16,color: Colors.black54),
                                            ),

                                          ]))
                                        ],
                                      ),

                                      SizedBox(height: 32.0),

                                      Container(
                                        width: MediaQuery.of(context).size.width,
                                        child: _isLoading
                                            ? CupertinoActivityIndicator(
                                          radius: 20.0,
                                        )
                                            : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _buttonColor,
                                            elevation: 5, // Adjust the elevation to make it look elevated
                                            shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                                          ),
                                          onPressed: () {
                                            /*if (_formKey.currentState != null &&
                                              _formKey.currentState!.validate()) {
                                            _formKey.currentState!.save();
                                            *//*_login();*//*
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => MaintenanceTicketCreation()));
                                          }*/

                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => SalesDashboard()));
                                          },
                                          child: Text('Login',
                                              style: TextStyle(
                                                  color: Colors.white
                                              )),
                                        ),
                                      ),

                                      /*SizedBox(height: 5),

                                    GestureDetector(onTap: ()
                                    {
                                      navigateToPDFView(context);
                                    },
                                        child: Container(
                                            width: MediaQuery.of(context).size.width,
                                            child : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children:[
                                                  Text('Not Registered?',
                                                      style: TextStyle(color: Colors.black54)),

                                                  Text('Click here for instructions',
                                                      style: TextStyle(color: Colors.black54,
                                                          fontWeight: FontWeight.bold,
                                                          decoration: TextDecoration.underline))
                                                ])))*/]))

                        )
                    ),
                    /*Visibility(
                      visible: isVisibleResetPassForm,
                      child:Expanded(child:Container(


                          padding: EdgeInsets.only(left: 32,right: 32,top: 70),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [

                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 0, // Spread radius
                                  blurRadius: 20, // Blur radius
                                  offset: Offset(0, -10),

                                  // Shadow position
                                ),
                              ],

                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(50),
                                  topRight: Radius.circular(50)
                              )
                          ),
                          child: Form(
                              key: _resetformKey,
                              child: ListView(

                                  children: [
                                    Container(

                                      padding: EdgeInsets.only(top: 5),
                                      child: TextFormField(

                                        controller: resetemailController,
                                        focusNode: _resetemailFocusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Registered Email Address',
                                          filled: true,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(5.0),
                                            borderSide: BorderSide(
                                              color: Colors.black12,
                                            ),
                                          ),
                                          fillColor: Colors.white,
                                          labelStyle: TextStyle(
                                            color: Colors.black54, // Set the label text color to black
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Color(int.parse('0xFF30D5C8'))),
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),

                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                          {
                                            return 'Please enter your email address';
                                          }
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
                                          {
                                            return 'Please enter a valid email address';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) => resetemail = value!,
                                      ),),


                                    SizedBox(height: 32.0),

                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      child: _isLoadingResetPass
                                          ? CupertinoActivityIndicator(
                                        radius: 20.0,
                                      )
                                          : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _resetbuttonColor,
                                          elevation: 5, // Adjust the elevation to make it look elevated
                                          shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                                        ),
                                        onPressed: isResetPassButtonDisabled ? null : () {
                                          if (_resetformKey.currentState != null &&
                                              _resetformKey.currentState!.validate()) {
                                            _resetformKey.currentState!.save();

                                            if(resetemailController.text.trim() == 'demouser@ca-eim.com')
                                            {
                                              _scaffoldMessengerKey.currentState?.showSnackBar(
                                                SnackBar(
                                                  content: Text('Reset password is not allowed for Demo User'),
                                                ),
                                              );
                                            }
                                            else
                                            {
                                              _resetpass();
                                            }
                                          }
                                        },
                                        child: Text('Reset Password',
                                            style: TextStyle(
                                                color: Colors.white
                                            )),
                                      ),
                                    ),

                                    Container(
                                        width: MediaQuery.of(context).size.width,
                                        child:ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(int.parse('0xFF30D5C8')),
                                              elevation: 5, // Adjust the elevation to make it look elevated
                                              shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                                            ),
                                            onPressed: () {

                                              setState(() {
                                                usernameController.text = resetemailController.text;
                                                resetemailController.clear();
                                                isVisibleResetPassForm = false;
                                                isVisibleLoginForm = true;
                                              });
                                            },
                                            child: Text('Cancel',
                                                style: TextStyle(
                                                    color: Colors.white
                                                ))))]))))),
                  Visibility(
                      visible: isVisibleOTPForm,
                      child:Expanded(child:Container(

                          padding: EdgeInsets.only(left: 32,right: 32,top: 30),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 0, // Spread radius
                                  blurRadius: 20, // Blur radius
                                  offset: Offset(0, -10),
                                  // Shadow position
                                ),
                              ],
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(50),
                                  topRight: Radius.circular(50)
                              )
                          ),
                          child: Form(
                              key: _otpformKey,
                              child: ListView(
                                  children:[

                                    Icon(Icons.mark_email_read_outlined, size: 100,
                                        color: Color(0xFF30D5C8)), // Mobile phone icon
                                    SizedBox(height: 20),
                                    Text(
                                      'Enter Verification Code',
                                      style: TextStyle(fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 5.0),
                                    Center(child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "We've sent you an OTP on ",
                                            style: TextStyle(color: Colors.black54),

                                          ),
                                          TextSpan(
                                            text: maskedEmail, // The masked email value
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), // Bold style
                                          ),

                                        ],
                                      ),
                                    ),),

                                    Text(
                                        ". Please enter that code below to continue."
                                        ,style: TextStyle(color: Colors.black54),
                                        textAlign: TextAlign.center// Regular text style
                                    ),

                                    Padding(
                                      padding: EdgeInsets.only(left: 5,right: 5,top: 16),
                                      child: PinCodeTextField(
                                        appContext: context,
                                        pastedTextStyle: TextStyle(
                                          color: Colors.green.shade600,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        length: 4, // Specify the length of OTP
                                        onChanged: (value) {
                                          currentText = value;
                                        },
                                        pinTheme: PinTheme(
                                            shape: PinCodeFieldShape.box,
                                            borderRadius: BorderRadius.circular(15),
                                            fieldHeight: 50,
                                            fieldWidth: 50,
                                            activeFillColor: Color(0xFF30D5C8),
                                            inactiveFillColor: Colors.white,
                                            activeColor: Color(0xFF30D5C8),
                                            inactiveColor: Colors.grey,
                                            borderWidth: 1,
                                            selectedColor: Color(0xFF30D5C8)
                                        ),
                                        controller: otpController,
                                        keyboardType: TextInputType.number,
                                        onCompleted: (value) {
                                          // OTP entry is complete
                                        },
                                        obscureText: true,
                                      ),
                                    ),
                                    SizedBox(height: 20),

                                    Visibility(visible: isVisibleTimer,
                                      child: Column(children: [
                                        Text(
                                          "Resend OTP in: $_formattedTime", // Display remaining time
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 16, color: Colors.black54),
                                        ),
                                        SizedBox(height: 20),


                                      ],),),

                                    Visibility(visible: _isButtonEnabled,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(int.parse('0xFF30D5C8')), // Change button color based on enabled state
                                        ),
                                        onPressed: () {
                                          sendOTP(usernamee);
                                          setState(() {
                                            _isButtonEnabled = false;
                                            isVisibleTimer = true;
                                            _startTimer();
                                          });

                                        }, // Disable button if not enabled
                                        child: Text(
                                          'Resend OTP',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),),

                                    SizedBox(height: 10),

                                    ElevatedButton(

                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _buttonColor,
                                      ),
                                      onPressed: () {

                                        if (currentText.length == 4) {
                                          final generatedOTP = generatedotp;
                                          final enteredOTP = currentText;

                                          if (enteredOTP == generatedOTP) {

                                            socket.emit('deleteMyId', socket_data);

                                            isOTPVerified = true;
                                            isAnotherDevice = true;

                                            _directlogin();
                                          }
                                          else {
                                            isOTPVerified = false;
                                            isAnotherDevice = false;
                                            Fluttertoast.showToast(msg: 'Incorrect OTP');
                                          }
                                        }
                                        else
                                        {
                                          isOTPVerified = false;
                                          isAnotherDevice = false;
                                          Fluttertoast.showToast(msg: 'Please enter a 4-digit OTP');
                                        }
                                      },
                                      child: Text('Verify',
                                          style: TextStyle(
                                              color: Colors.white
                                          )),
                                    )
                                  ]
                              ))))),*/
                  ])
            ),
           )
        );}}
