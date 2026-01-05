// Minimal working react-tooltip example for debugging
import 'react-tooltip/dist/react-tooltip.css';
import { Tooltip } from 'react-tooltip';
import React, { useEffect, useState } from 'react';
import { Formik, Form, Field } from 'formik';
import { GoogleLogin, useGoogleLogin } from '@react-oauth/google';
import * as Yup from 'yup';
import { Check, X, Lock, Mail, User } from 'lucide-react';
import { useDispatch, useSelector } from 'react-redux';
import {
  setUsername,
  checkUserNameAvailability,
  setUserId,
  setIsAvailable,
} from '@/stores/profileSlice';
import axios from '@/lib/axios-config';
// import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip"
import { useNavigate } from 'react-router-dom';
import { createPageUrl } from '@/utils';
import { toast } from 'sonner';
import { Circles } from 'react-loader-spinner';



export default function CreateAccount({
  onSubmit,
  submitText,
  className = '',
}) {
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [step, setStep] = useState(0);
  const prevStep = () => {
    setStep((s) => Math.max(s - 1, 0));
    return false;
  };
  const nextStep = () => {
    // go to next step
    setStep((s) => Math.min(s + 1, 1));
  };
  const navigate = useNavigate();

  useEffect(() => {
    dispatch(setIsAvailable({ isAvailable: null }));
  }, []);

  //
  const dispatch = useDispatch();
  const [usernameLastChecked, setUsernameLastChecked] = useState('');
  const { isAvailable, isChecking, error: profileError } = useSelector(
    (state) => state.profile
  );
  let t = null;

  // Validation Schema
  const SignupSchema = Yup.object({
    email: Yup.string()
      .required('Email is required')
      .test(
        'email-format',
        'Invalid email format',
        (value) => {
          if (!value.includes('@')) return false;
          return /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(value) && 
                !/[^a-zA-Z0-9.@_-]/.test(value);
        }
      ),
    password: Yup.string(),
    passwordConfirmation: Yup.string()
      .oneOf([Yup.ref('password'), null], 'Passwords must match')
      .required('Required'),
    username: Yup.string()
      .required('Username is required')
      .min(3, 'Username must be at least 3 characters')
      .max(30, 'Username must not exceed 30 characters')
      .test(
        'valid-chars',
        'Username can only contain Hebrew/English letters, numbers, underscores, hyphens, and dots',
        (value) => !value || /^[\u0590-\u05FFa-zA-Z0-9_\-.]*$/.test(value)
      )
      .test(
        'no-consecutive-special',
        'Username cannot contain consecutive special characters (_.-)',
        (value) => !value || !/[_.-]{2,}/.test(value)
      )
      .test(
        'min-length',
        'Username must be at least 3 characters',
        (value) => !value || value.length >= 3
      )
      .test(
        'max-length',
        'Username must not exceed 30 characters',
        (value) => !value || value.length <= 30
      ),
    discordUsername: Yup.string()
      .test(
        'discord-format',
        'Invalid Discord username format. Use: username (3-30 chars, alphanumeric + _) or username#1234',
        (value) => {
          // New format: 3-30 alphanumeric + underscore
          const newFormat = /^[a-zA-Z0-9_]{3,30}$/;
          // Legacy format: username#1234
          const legacyFormat = /^[a-zA-Z0-9_.]{2,32}#\d{4}$/;
          return newFormat.test(value) || legacyFormat.test(value);
        }
      )
      .required('Required'),
  });

  const handleSubmit = async (values, { setSubmitting, setFieldError }) => {
    console.log('handleSubmit called', { values });
    setIsSubmitting(true);
    try {
      const response = await axios.post('/api/users/signup', {
        Email: values.email,
        Password: values.password,
        Username: values.username,
        DiscordUsername: values.discordUsername,
      });

      const userId = response?.data?.user_id;
      if (userId) {
        localStorage.setItem('userId', userId);
        localStorage.setItem('isAuthenticated', 'true');
        dispatch(setUserId({ userId }));
        
        // Show success popup
        toast.success('Account created successfully!', {
          description: 'Redirecting to your sign in page...',
          duration: 3000
        });
        
        // Navigate after a short delay to show the success message
        setTimeout(() => {
          navigate(createPageUrl('SignIn'));
        }, 1500);
      } else {
        throw new Error('User ID not received in response');
      }
    } catch (error) {
      console.error('Signup error:', error);
      const errorMessage = error.response?.data?.message || 
                          error.message || 
                          'Signup failed. Please check your information and try again.';
      
      // Show error popup
      toast.error('Signup Failed', {
        description: errorMessage,
        duration: 5000,
        position: 'top-center',
        // action: {
        //   label: 'Try Again',
        //   onClick: () => window.location.reload()
        // }
      });
      
      // Also set field error for form validation
      setFieldError('general', errorMessage);
    } finally {
      setIsLoading(false);
      setIsSubmitting(false);
    }
  };

  const validateEmail = email => {
    if (email === "") {
      return "Email is required";
    }
    const emailRegex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i;
    return emailRegex.test(email) ? null : 'Invalid email address';
  };

  const validateUsername = (username) => {
    //
    let error;

    // don't validate if usernameLastCheck is the same
    if (!username || username === usernameLastChecked) return;

    // username changed -> clear interval
    if (t) clearTimeout(t);

    // else, create new timeout
    if (!t || t > 1) {
      t = setTimeout(async () => {
        setUsernameLastChecked(username);
        const result = await dispatch(checkUserNameAvailability(username));
        // const userId = result?.data?.userId;
        // if (userId) {
        //     localStorage.setItem('userId', userId); // Store userId in localStorage
        //     dispatch(setUserId({ userId })); // Store userId in Redux state
        // }
        console.log('result', result);
      }, 1000);
    }
  };

  // google login
  const login = useGoogleLogin({
    onSuccess: (tokenResponse) => {
      /* handle success */
      console.log('Google login successful:', tokenResponse);
    },
    onError: () => {
      /* handle error */
    },
  });

  const validatePassword = (value) => {
    //
    const validators = [
      {
        valfunc: (value) => value.length >= 8,
        vlamsg: 'Password must be at least 8 characters long',
      },
      {
        valfunc: (value) => /[a-z]/.test(value),
        vlamsg: 'Password must contain at least one lowercase letter',
      },
      {
        valfunc: (value) => /[A-Z]/.test(value),
        vlamsg: 'Password must contain at least one uppercase letter',
      },
      {
        valfunc: (value) => /[0-9]/.test(value),
        vlamsg: 'Password must contain at least one number',
      },
      {
        valfunc: (value) => /[@#$!%*?&]/.test(value),
        vlamsg: 'Password must contain at least one special character',
      },
    ];

    //
    const result = [];
    let isValid = true;

    // iterate each option from validators
    validators.forEach((validator) => {
      if (validator.valfunc(value)) {
        result.push(
          <div className="text-green-400" key={validator.vlamsg}>
            <Check className="inline-block mr-2" />
            <span className="text-white">{validator.vlamsg}</span>
          </div>
        );
      } else {
        result.push(
          <div className="text-red-400" key={validator.vlamsg}>
            <X className="inline-block mr-2" />
            <span className="text-white">{validator.vlamsg}</span>
          </div>
        );
        isValid = false;
      }
    });

    // Formik expects `null` when the field is valid (no error).
    return isValid ? null : result;
  };

  const validatePasswordConfirmation = (conf, values) => {
    let error;
    if (!conf) {
      error = "Password confirmation is required.";
    } else if (conf !== values.password) {
      error = "Passwords do not match.";
    }

    return error;
  };


  const validateForm = (values) => {
    const errors = {};

    errors.email = 'email not valid';

    if (values.password.length < 8) {
      errors.password = "Password must be at least 8 characters";
    }

    if (values.passwordConfirmation !== values.password) {
      errors.passwordConfirmation = "Passwords must match";
    }

    return errors;
  };

  const checkAreFirstThreeValid = (errors, touched) => {
    let isValid = true;

    // check email, password, passwordConfirmation
    if (errors.email || !touched.email) {
      return false;
    }

    if (errors.password) {
      let innerResult = true;
      errors.password.forEach((err) => {

        if (err.props.className.includes('text-red-400')) {
          innerResult = false;
        }
      });

      if (!innerResult) {
        return false;
      }
    }

    if (errors.passwordConfirmation || !touched.passwordConfirmation) {
      return false;
    }

    return isValid;
  }

  const checkAreLastTwoValid = (errors, touched) => {
    // Check if there are any validation errors for username or discordUsername
    if (errors.username || errors.discordUsername) {
      return false;
    }
    
    // Check if the fields have been touched
    if (!touched.username || !touched.discordUsername) {
      return false;
    }
    
    // If we're checking availability, wait for that to complete
    if (isChecking) {
      return false;
    }
    
    // If we have an availability check result, use it
    // Otherwise (null means not checked yet), only check basic validation
    if (isAvailable !== null) {
      return isAvailable;
    }
    
    // If no availability check yet, just check basic validation
    return true;
  };

  return (
    <>

      {isLoading && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="w-full max-w-md bg-white dark:bg-gray-800 rounded-xl shadow-md p-8">
            <div className="w-16 h-16 border-4 border-teal-200 border-t-teal-700 rounded-full animate-spin mx-auto"></div>
            <p className="mt-4 text-center text-gray-600 dark:text-gray-300">Loading...</p>
          </div>
        </div>
      )}

      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-50 to-teal-50 dark:from-gray-900 dark:to-gray-800 p-4">
        <div className="max-w-md w-full">
          {/* <!-- Logo --> */}
          <div className="mx-auto mb-6">
            <img
              src="https://tovplay.org/lovable-uploads/b1e62294-a51b-4e1e-8f0e-4e1472f1a562.png"
              alt="TovPlay Logo"
              className="h-16 mx-auto"
            />
          </div>

          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-gray-800 dark:text-white mb-2">Create Account</h1>
            <p className="text-gray-600 dark:text-gray-300">Join our community of gamers</p>
          </div>

          <Formik
            initialValues={{
              email: '',
              password: '',
              passwordConfirmation: '',
              username: '',
              discordUsername: ''
            }}
            validationSchema={SignupSchema}
            validateOnChange={true}
            validateOnBlur={true}
            validateOnMount={false}
            onSubmit={handleSubmit}
          >
            {({
              errors,
              touched,
              isValid,
              handleChange,
              setFieldTouched,
              validateField,
              values,
              submitForm,
              //isSubmitting,
            }) => {
              // Move this above the return statement
              const areFirstThreeValid = checkAreFirstThreeValid(
                errors,
                touched
              );

              //
              const areLastTwoValid = checkAreLastTwoValid(errors, touched);

              return (
                <Form>
                  {/* Step 1 */}
                  <div className={`${step === 0 ? "block" : "hidden"}`}>
                    {/* <!-- Google Sign-up Button --> */}
                    {/* <button
                      type="button"
                      onClick={() => login()}
                      className="w-full flex items-center justify-center bg-white border border-gray-300 text-gray-700 py-3 px-4 rounded-xl shadow-sm hover:bg-gray-50 transition mb-6"
                    >
                      <img
                        src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png"
                        alt="Google logo"
                        className="w-5 h-5 mr-2"
                      />
                      Sign in with Google
                    </button> */}

                    {/* <!-- Divider --> */}
                    {/*<div className="flex items-center my-6">
                      <div className="flex-grow border-t border-gray-300"></div>
                      <span className="mx-4 text-gray-500">OR</span>
                      <div className="flex-grow border-t border-gray-300"></div>
                    </div>*/}

                    {/* <!-- Email Input --> */}
                    <div className="space-y-6">
                      <div className="mb-4">
                        <label htmlFor="email" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                          Email Address
                        </label>
                        <Field
                          name="email"
                          type="email"
                          className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 bg-white dark:bg-gray-700 text-gray-900 dark:text-white ${
                            errors.email && touched.email
                              ? 'border-red-500 focus:ring-red-200 dark:border-red-500'
                              : 'focus:border-teal-500 focus:ring-teal-200 border-gray-300 dark:border-gray-600'
                          }`}
                          onChange={(e) => {
                            handleChange(e);
                            setFieldTouched('email', true, false);
                            validateField('email');
                          }}
                          onBlur={(e) => {
                            setFieldTouched('email', true, true);
                            validateField('email');
                          }}
                          value={values.email}
                        />
                        <div className="text-xs text-red-500 mt-2">
                          {errors.email && touched.email ? (
                            <div className="flex items-center">
                              <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                              </svg>
                              {errors.email}
                            </div>
                          ) : (
                            <div>&nbsp;</div>
                          )}
                        </div>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                        <Lock className="w-4 h-4 inline mr-2" />
                        Password
                      </label>
                      <div>
                        <Field
                          name="password"
                          type="password"
                          placeholder="Create a password"
                          autoComplete="off"
                          validate={validatePassword}
                          value={values.password}
                          className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                          maxLength={20}
                          data-tooltip-id={'password-error-tip'}
                          // data-tooltip-html={errors.password}
                          data-html={true}
                        />
                        <Tooltip id="password-error-tip" place="right">
                          {errors.password}
                        </Tooltip>
                        <div>&nbsp;</div>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                        <Lock className="w-4 h-4 inline mr-2" />
                        Confirm Password
                      </label>
                      <Field
                        name="passwordConfirmation"
                        type="password"
                        placeholder="Confirm your password"
                        autoComplete="off" // validate={validatePasswordConfirmation}
                        onChange={(e) => {
                          handleChange(e);
                          setFieldTouched('passwordConfirmation', true, false);
                          validateField('passwordConfirmation');
                        }}
                        onBlur={(e) => {
                          setFieldTouched('passwordConfirmation', true, true);
                          validateField('passwordConfirmation');
                        }}
                        value={values.passwordConfirmation}
                        className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        maxLength={20}
                      />
                      <div className="text-xs text-red-600 mt-2">
                        {errors.passwordConfirmation &&
                        touched.passwordConfirmation ? (
                          <div>{errors.passwordConfirmation}</div>
                        ) : (
                          <div>&nbsp;</div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Step 2 */}
                  <div className={`${step === 1 ? "block" : "hidden"}`}>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                        <User className="w-4 h-4 inline mr-2" />
                        Username
                      </label>
                      <div className="relative">
                        <Field
                          name="username"
                          type="text"
                          className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 bg-white dark:bg-gray-700 text-gray-900 dark:text-white ${
                            errors.username && touched.username
                              ? 'border-red-500 focus:ring-red-200 dark:border-red-500'
                              : 'focus:border-teal-500 focus:ring-teal-200 border-gray-300 dark:border-gray-600'
                          }`}
                          dir="auto"
                          style={{ textAlign: 'start' }}
                          onChange={(e) => {
                            // Only validate on change if we already have an error
                            const shouldValidate = errors.username && touched.username;
                            handleChange(e);
                            setFieldTouched('username', true, false);
                            if (shouldValidate) {
                              validateField('username');
                            }
                          }}
                          onBlur={(e) => {
                            handleBlur(e);
                            setFieldTouched('username', true, true);
                            validateField('username');
                          }}
                          onKeyDown={(e) => {
                            // Allow all key presses during input
                            // Validation will happen on blur
                            e.stopPropagation();
                          }}
                          value={values.username}
                        />
                      </div>
                      <div className="text-xs text-red-500 mt-2">
                        {errors.username && touched.username ? (
                          <div className="flex items-center">
                            <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                            </svg>
                            {errors.username}
                          </div>
                        ) : values.username && values.username.length < 3 ? (
                          <p className="text-xs text-red-600 mt-2 flex items-center">
                            <X className="w-3 h-3 mr-1" />
                            Username must be at least 3 characters long
                          </p>
                        ) : isAvailable === true ? (
                          <p className="text-xs text-green-600 mt-2 flex items-center">
                            <Check className="w-3 h-3 mr-1" />
                            This username is available
                          </p>
                        ) : isAvailable === false ? (
                          <p className="text-xs text-red-600 mt-2 flex items-center">
                            <X className="w-3 h-3 mr-1" />
                            This username is not available
                          </p>
                        ) : isChecking ? (
                          <p className="text-xs text-gray-500 mt-2">
                            Checking username availability...
                          </p>
                        ) : (
                          <div className="text-xs text-gray-500 mt-1">
                            Can contain Hebrew/English letters, numbers, and _ - .
                          </div>
                        )}
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                        <User className="w-4 h-4 inline mr-2" />
                        Discord Username
                      </label>
                      <Field
                        name="discordUsername"
                        autoComplete="off"
                        spellCheck="false"
                        type="text"
                        maxLength={20}
                        className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
                        placeholder="Choose a discord username"
                        onChange={(e) => {
                          handleChange(e);
                          setFieldTouched('discordUsername', true, false);
                          validateField('discordUsername');
                        }}
                        onBlur={(e) => {
                          setFieldTouched('discordUsername', true, true);
                          validateField('discordUsername');
                        }}
                        // onBlur={() => setFieldTouched('discordUsername', true)}
                        value={values.discordUsername}
                      />
                      <div className="text-xs text-red-600 mt-2">
                        {errors.discordUsername && touched.discordUsername ? (
                          <div>{errors.discordUsername}</div>
                        ) : (
                          <div>&nbsp;</div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Step 1: Back and Next Buttons */}
                  <div className={`${step === 0 ? 'space-y-3' : 'hidden'}`}>
                    <button
                      type="button"
                      onClick={() => {
                        // Mark core fields as touched so Formik validates them before moving
                        setFieldTouched('email', true);
                        setFieldTouched('password', true);
                        setFieldTouched('passwordConfirmation', true);
                        nextStep();
                      }}
                      disabled={!areFirstThreeValid || !Object.keys(touched).length > 0}
                      className={`w-full bg-teal-600 hover:bg-teal-700 text-white py-2 rounded transition-colors ${
                        !areFirstThreeValid || !Object.keys(touched).length > 0
                          ? 'opacity-50 cursor-not-allowed'
                          : ''
                      }`}
                    >
                      Continue
                    </button>

                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">Already have account? <a className="text-teal-500 dark:text-teal-400" href="/signin" >Sign in</a></p>
                  </div>

                  {/* Step 2: Back and Submit Buttons */}
                  <div className={`${step === 1 ? 'space-y-3' : 'hidden'}`}>
                    <button
                      type="button"
                      onClick={(e) => {
                        e.preventDefault();
                        prevStep();
                      }}
                      className="w-full bg-gray-200 hover:bg-gray-300 text-gray-800 py-2 rounded transition-colors flex items-center justify-center gap-2"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                      </svg>
                      Back
                    </button>
                    <button
                      type="submit"
                      disabled={!areLastTwoValid || isSubmitting}
                      className={`w-full py-2 px-4 rounded-md text-white font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors ${
                        isSubmitting || !areLastTwoValid
                          ? 'bg-teal-400 dark:bg-teal-800 cursor-not-allowed'
                          : 'bg-teal-600 hover:bg-teal-700 dark:bg-teal-700 dark:hover:bg-teal-600 focus:ring-teal-500 dark:focus:ring-offset-gray-800'
                      }`}
                    >
                      {isSubmitting ? 'Creating Account...' : 'Create Account'}
                    </button>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">Already have account? <a className="text-teal-500 dark:text-teal-400" href="/signin" >Sign in</a></p>
                  </div>
                </Form>
              );
            }}
          </Formik>
          {/* Toast container is now in App.jsx */}
        </div>
          {isSubmitting &&
                  <div class="fixed lt-0 top-0 w-full h-full bg-black bg-opacity-50 flex items-center justify-center z-50">
                    <Circles
                      height="80"
                      width="80"
                      color="#00a2ff"
                      ariaLabel="circles-loading"
                      wrapperStyle={{}}
                      wrapperClass=""
                      visible={true}
                      />
                    </div>
                  }
      </div>
    </>
  );
}