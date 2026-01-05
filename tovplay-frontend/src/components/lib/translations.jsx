export const translations = {
  en: {
    // Requirements Dialog
    requirementsDialog: {
      title: "Additional Setup Required",
      missingAvailability: "You need to set your availability before finding players.",
      missingGames: "You need to add at least one game to your profile.",
      setAvailability: "Set Availability",
      addGames: "Add Games",
      close: "Close"
    },
    
    // General
    continue: "Continue",
    pendingGameRequests: "My Game Requests",
    pendingGameRequestsSent: "Sent Game Requests",
    defaultRequestMessage: "Hey! Would you be up for a game of {game}?",
    thisGame: "this game",
    goBack: "Go Back",
    save: "Save",
    cancel: "Cancel",
    at: "at",
    settings: "Settings",
    editProfile: "Edit Profile",
    logout: "Logout",
    loading: "Loading...",
    
    // Languages
    languages: {
      english: "English",
      hebrew: "Hebrew",
      russian: "Russian",
      arabic: "Arabic",
      amharic: "Amharic"
    },
    
    // Profile
    profile: {
      title: "Your Profile",
      description: "Manage your profile information",
      saveChanges: "Save Changes",
      cancel: "Cancel",
      success: {
        update: "Profile updated successfully!"
      },
      errors: {
        usernameRequired: "Username is required",
        descriptionTooLong: "Description must be 200 characters or less",
        loginRequired: "Please log in to save your profile",
        saveFailed: "Failed to save profile. Please try again.",
        loadFailed: "Failed to load profile data"
      },
      fields: {
        username: "Username",
        description: "About Me",
        languages: "Languages",
        communication: "Communication Style",
        openness: "Openness to New Players"
      },
      description: {
        placeholder: "Tell us about yourself...",
        default: "This user hasn't added a description yet"
      },
      communication: {
        text: "Text chat only",
        voice: "Voice chat",
        video: "Video chat",
        minimal: "Minimal chat"
      },
      openness: {
        openToAll: "Open to all",
        friendsOnly: "Friends only",
        inviteOnly: "Invite only",
        open: "Open",
        careful: "Careful",
        previousContactsOnly: "Only previous contacts"
      }
    },

    // Days of the week
    monday: "Monday",
    tuesday: "Tuesday",
    wednesday: "Wednesday",
    thursday: "Thursday",
    friday: "Friday",
    saturday: "Saturday",
    sunday: "Sunday",

    // Layout
    mySchedule: "My Schedule",
    findPlayers: "Find Players",
    friends: "Friends",

    // Welcome Page
    welcomeToTovPlay: "Welcome to TovPlay",
    welcomeSubtitle: "A calm, comfortable space designed for gamers to connect at their own pace. We prioritize your comfort and accessibility above all else.",
    getStarted: "Get Started",
    signIn: "Sign In",
    comfortFirst: "Comfort First",
    comfortFirstDesc: "Every feature is designed to minimize stress and maximize your comfort while connecting with others.",
    yourControl: "Your Control",
    yourControlDesc: "Set your own pace, choose your availability, and customize every aspect of your experience.",
    gentleConnections: "Gentle Connections",
    gentleConnectionsDesc: "Find like-minded players through shared interests, not pressure or competition.",
    
    // Onboarding
    createYourAccount: "Create Your Account",
    stepOf: "Step {current} of {total}",
    emailAddress: "Email Address",
    password: "Password",
    chooseUsername: "Choose Your Username",
    username: "Username",
    usernameAvailable: "This username is available",
    usernameHint: "This is how other players will know you. Choose something that feels right for you.",
    selectYourGames: "Select Your Games",
    selectGamesHint: "Choose the games you enjoy playing (optional)",
    doThisLater: "I'll do this later",
    setYourAvailability: "Set Your Availability",
    availabilityHint: "Let others know when you're free to play (optional)",
    dragToSelect: "Click and drag to select multiple time slots.",
    onboardingComplete: "Welcome to TovPlay!",
    onboardingCompleteSubtitle: "Your profile is all set up! You can now start connecting with other players at your own pace and comfort level.",
    goToDashboard: "Go to Dashboard",

    // Dashboard
    welcomeBack: "Welcome back, {username}!",
    pendingRequests: 'You have <span class="font-semibold text-teal-600">{count}</span> pending game requests.',
    noPendingRequests: "No pending requests. Great job staying on top of things!",
    
    // Schedule
    yourGamingSchedule: "Your Gaming Schedule",
    setWeeklyAvailability: "Set your weekly gaming availability to help others find the best time to connect.",
    weeklyAvailability: "24/7 Weekly Availability",
    time: "Time",
    clickAndDragInstruction: "Click and drag to select multiple time slots",
    clearAll: "Clear All",
    changesSaved: "Changes Saved!",
    saveSchedule: "Save Schedule",
    unableToSaveEmptySchedule: "Unable to save when all slots are empty, please select time slots to save",
    noTimeSlotsSelected: "No Time Slots Selected",
    selectTimeSlotsOrEnableCustom: "Please select at least one time slot for your availability or enable 'I prefer custom game requests' if you don't want to set a fixed schedule.",
    gotIt: "Got it!",
    saveForFutureWeeks: "Save this availability for future weeks?",
    scheduleSavedSuccessfully: "Schedule saved successfully!",
    scheduleSavedToLocal: "Schedule saved locally",
    saveScheduleError: "Failed to save schedule. Please try again.",
    scheduleCleared: "Schedule cleared",
    nextUp: "Next Up",
    noUpcomingSessions: "No Upcoming Sessions",
    
    // PlayerCard
    noAvailableSlots: "No available slots",
    offline: "Offline",
    noGamesSelected: "No games selected",
    noLanguagesSelected: "No languages selected",
    sharedLanguages: "Shared languages",
    requestSent: "Request sent",
    requestToPlay: "Request to play",
    showLess: "Show less",
    moreCount: "+{count} more",
    noUpcomingSessionsDesc: "Your calendar is free! Find a player to schedule a new game.",
    playingWith: "Playing with {player}",
    joinGame: "Join Game",
    viewDetails: "View Details",
    cancleGame: "Cancel Game",
    onlineNow: "Online Now",
    noFriendsOnline: "No friends are currently online.",
    quickActions: "Quick Actions",
    setYourSchedule: "Set Your Schedule",
    comfortSettings: "Comfort Settings",
    pendingGameRequests: "Pending Game Requests",
    pendingGameRequestsSent: "My Game Requests",
    recived: "Received",
    send: "Send",
    
    // Cancel Session Dialog
    cancelSession: {
      title: "Send a cancel message",
      description: "Inform the players about the cancellation of the session on {date} at {time}.",
      messagePrompt: "For {participants} wanting to play {game}, please provide a reason for the cancellation:",
      placeholder: "Type your cancel message here..."
    },
    unexpectedLinkFormat: "Unexpected link format: {data}",
    unexpectedMeetingError: "Unexpected meeting link error: {data}",
    userNotInGuild: "{name} is not in the TovPlay guild",
    userNotInGuildDesc: "you'll need to manually find them in Discord",
    discordBotError: "Our Discord bot can't access guild info",
    
    // Find Players
    findYourTeammate: "Find Your Next Teammate",
    findPlayersSubtitle: "Discover like-minded players based on the games you love and when you're free to play.",
    findPlayersByGame: "Find Players by Game",
    noPlayersFound: "No available players found",
    noPlayersFoundDesc: "No {game} players found with matching availability. Try checking other games.",
    onlineNowDesc: "Players who are online right now and share your gaming interests.",
    playersWithMatchingAvailability: "{game} Players with Matching Availability",
    searchingForPlayers: "Searching for players...",
    noAvailableSlots: "No available slots",
    offline: "Offline",
    noGamesSelected: "No games selected",
    noLanguagesSelected: "No languages selected",
    sharedLanguages: "Shared Languages",
    showLess: "Show less",
    moreCount: "+{count} more",
    requestSent: "Request Sent",
    requestToPlay: "Request to Play",
    requestSentTitle: "Request Sent!",
    requestSentBody: "Your game request has been sent to {username}.",
    close: "Close",
    requestToPlayTitle: "Request to Play",
    gameLabel: "Game",
    selectTimeSlots: "Select time slots (select multiple if available)",
    checkingAvailability: "Checking availability...",
    noTimeSlotsFound: "No available time slots found.",
    requestSentTag: "Request sent",
    timeSlotsSelected: "{count} time slot{plural} selected",
    yourMessage: "Your Message",
    required: "(required)",
    writeFriendlyMessage: "Write a friendly message...",
    characters: "characters",
    sending: "Sending...",
    sendRequest: "Send Request",
    cancelAction: "Cancel",

    // Notifications
    notificationsTitle: "Notifications",
    notificationsEmpty: "No notifications yet.",
    disconnectTitle: "Real-time notifications disconnected",
    disconnectDescription: "Trying to reconnect...",
    dismiss: "Dismiss",
    cancellationReason: "Cancellation Reason: {reason}",
    markAllAsRead: "Mark all as read",
    marking: "Marking...",

    // Game Requests
    incomingRequestTitle: "{sender} wants to play with you!",
    youAskedToPlay: "You've asked {recipient} to play with you!",
    decline: "Decline",
    accept: "Accept",
    cancelGameRequest: "Cancel Game Request",
    
    // GameRequestSentCard
    gameRequestSentCard: {
      youAsked: "You asked {username} to play",
      cancelRequest: "Cancel Request"
    },

    // My Profile
    languages: "Languages",
    communication: "Communication",
    opennessToNewUsers: "Openness to New Users",
    favoriteGames: "Favorite Games",
    friendsCount: "Friends",
    gamesCount: "Games",
    sessionsCount: "Sessions",

    // Settings
    comfortAndAccessibility: "Comfort & Accessibility Settings",
    comfortAndAccessibilityDesc: "Customize your experience to match your needs and preferences. All settings are designed to enhance your comfort.",
    visualTheme: "Visual Theme",
    chooseTheme: "Choose your preferred theme",
    lightTheme: "Light Theme",
    darkTheme: "Dark Theme",
    accessibility: "Accessibility",
    reduceMotion: "Reduce Motion",
    reduceMotionDesc: "Minimize animations and transitions for a calmer experience",
    fontSize: "Font Size",
    notifications: "Notifications",
    appLanguage: "App Language",
    chooseLanguage: "Choose your preferred language"
  },
  he: {
    // Requirements Dialog
    requirementsDialog: {
      title: "נדרשת הגדרה נוספת",
      missingAvailability: "עליך להגדיר זמינות לפני שתוכל למצוא שחקנים",
      missingGames: "עליך להוסיף לפחות משחק אחד לפרופיל שלך",
      setAvailability: "הגדר זמינות",
      addGames: "הוסף משחקים",
      close: "סגור"
    },
    
    // General
    continue: "המשך",
    pendingGameRequests: "בקשות משחק שלי",
    pendingGameRequestsSent: "בקשות משחק שנשלחו",
    defaultRequestMessage: "היי! מתאים לך לשחק משחק {game}?",
    thisGame: "משחק זה",
    goBack: "חזרה",
    save: "שמור",
    cancel: "ביטול",
    at: "ב-",
    settings: "הגדרות",
    editProfile: "ערוך פרופיל",
    logout: "התנתק",
    loading: "טוען...",
    
    // Languages
    languages: {
      english: "אנגלית",
      hebrew: "עברית",
      russian: "רוסית",
      arabic: "ערבית",
      amharic: "אמהרית"
    },
    saving: "שומר...",
    
    // Profile
    profile: {
      title: "הפרופיל שלך",
      description: "נהל את פרטי הפרופיל שלך",
      saveChanges: "שמור שינויים",
      cancel: "ביטול",
      errors: {
        usernameRequired: "נדרש שם משתמש",
        descriptionTooLong: "התיאור חייב להיות עד 200 תווים",
        loginRequired: "אנא התחבר כדי לשמור את הפרופיל שלך",
        saveFailed: "שמירת הפרופיל נכשלה. אנא נסה שוב.",
        loadFailed: "טעינת נתוני הפרופיל נכשלה",
        avatarUpdate: "שגיאה בעדכון תמונת הפרופיל"
      },
      success: {
        update: "הפרופיל עודכן בהצלחה!",
        avatarUpdate: "תמונת הפרופיל עודכנה בהצלחה"
      },
      fields: {
        username: "שם משתמש",
        description: "קצת עליי",
        languages: "שפות",
        communication: "סגנון תקשורת",
        openness: "פתיחות לשחקנים חדשים",
        games: "משחקים אהובים"
      },
      description: {
        placeholder: "ספר/י לנו על עצמך...",
        default: "למשתמש זה עדיין אין תיאור"
      },
      communication: {
        text: "צ'אט טקסט בלבד",
        voice: "צ'אט קולי",
        video: "שיחות וידאו",
        minimal: "מינימום שיחה"
      },
      openness: {
        openToAll: "פתוח לכולם",
        friendsOnly: "חברים בלבד",
        inviteOnly: "בהזמנה בלבד",
        open: "פתוח",
        careful: "זהיר",
        previousContactsOnly: "אנשים ששיחקתי איתם בעבר"
      },
      description: {
        placeholder: "ספר קצת על עצמך...",
        default: "למשתמש זה עדיין אין תיאור"
      },
      notFound: {
        title: "פרופיל לא נמצא",
        message: "לא הצלחנו למצוא את הפרופיל של {username}.",
        create: "נראה שעדיין לא יצרת פרופיל. תוכל ליצור אחד עכשיו!"
      },
      createProfile: "צור פרופיל"
    },

    // Days of the week
    monday: "יום שני",
    tuesday: "יום שלישי",
    wednesday: "יום רביעי",
    thursday: "יום חמישי",
    friday: "יום שישי",
    saturday: "שבת",
    sunday: "יום ראשון",

    // General
    continue: "המשך",
    goBack: "חזור",
    save: "שמור",
    
    // Schedule
    yourGamingSchedule: "לוח הזמנים שלך",
    setWeeklyAvailability: "קבע את זמינות המשחק השבועית שלך כדי לעזור לאחרים למצוא את הזמן הטוב ביותר להתחבר.",
    weeklyAvailability: "זמינות שבועית 24/7",
    time: "שעה",
    clickAndDragInstruction: "לחץ וגרור כדי לבחור כמה משבצות זמן",
    clearAll: "נקה הכל",
    changesSaved: "השינויים נשמרו!",
    saveSchedule: "שמור לוח זמנים",
    unableToSaveEmptySchedule: "לא ניתן לשמור כאשר כל המשבצות ריקות, אנא בחר משבצות זמן לשמירה",
    noTimeSlotsSelected: "לא נבחרו משבצות זמן",
    selectTimeSlotsOrEnableCustom: "אנא בחר לפחות משבצת זמינות אחת או הפעל 'אני מעדיף/ה בקשות משחק מותאמות אישית' אם אינך רוצה להגדיר לוח זמנים קבוע.",
    gotIt: "הבנתי!",
    saveForFutureWeeks: "לשמור זמינות זו לשבועות הבאים?",
    scheduleSavedSuccessfully: "לוח הזמנים נשמר בהצלחה!",
    scheduleSavedToLocal: "לוח הזמנים נשמר באופן מקומי",
    saveScheduleError: "שגיאה בשמירת לוח הזמנים. אנא נסה שוב.",
    scheduleCleared: "לוח הזמנים נוקה",
    cancel: "ביטול",
    settings: "הגדרות",
    editProfile: "ערוך פרופיל",
    logout: "התנתק",
    loading: "טוען...",

    // Layout
    mySchedule: 'הלו"ז שלי',
    findPlayers: "מצא שחקנים",
    friends: "חברים",

    // Welcome Page
    welcomeToTovPlay: "ברוכים הבאים ל-TovPlay",
    welcomeSubtitle: "מרחב רגוע ונוח שנועד לגיימרים להתחבר בקצב שלהם. אנו שמים בראש סדר העדיפויות את הנוחות והנגישות שלכם.",
    getStarted: "בואו נתחיל",
    signIn: "התחבר",
    comfortFirst: "נוחות לפני הכל",
    comfortFirstDesc: "כל תכונה מיועדת למזער מתח ולמקסם את הנוחות שלך בזמן התחברות עם אחרים.",
    yourControl: "השליטה בידיים שלך",
    yourControlDesc: "קבע את הקצב שלך, בחר את הזמינות שלך והתאם אישית כל היבט בחוויה שלך.",
    gentleConnections: "חיבורים עדינים",
    gentleConnectionsDesc: "מצא שחקנים דומים לך דרך תחומי עניין משותפים, לא לחץ או תחרות.",
    
    // Onboarding
    createYourAccount: "צור את החשבון שלך",
    stepOf: "שלב {current} מתוך {total}",
    emailAddress: "כתובת אימייל",
    password: "סיסמה",
    chooseUsername: "בחר שם משתמש",
    username: "שם משתמש",
    usernameAvailable: "שם המשתמש פנוי",
    usernameHint: "כך שחקנים אחרים יכירו אותך. בחר משהו שמרגיש לך נכון.",
    selectYourGames: "בחר את המשחקים שלך",
    selectGamesHint: "בחר את המשחקים שאתה נהנה לשחק (אופציונלי)",
    doThisLater: "אעשה זאת מאוחר יותר",
    setYourAvailability: "הגדר את הזמינות שלך",
    availabilityHint: "ספר לאחרים מתי אתה פנוי לשחק (אופציונלי)",
    dragToSelect: "לחץ וגרור כדי לבחור מספר משבצות זמן.",
    onboardingComplete: "ברוך הבא ל-TovPlay!",
    onboardingCompleteSubtitle: "הפרופיל שלך מוכן! עכשיו תוכל להתחיל להתחבר עם שחקנים אחרים בקצב ובנוחות שלך.",
    goToDashboard: "עבור לדאשבורד",

    // Dashboard
    welcomeBack: "ברוך שובך, {username}!",
    pendingRequests: 'יש לך <span class="font-semibold text-teal-600">{count}</span> בקשות משחק ממתינות.',
    noPendingRequests: "אין בקשות ממתינות. כל הכבוד על שמירת הסדר!",
    nextUp: "הבא בתור",
    noUpcomingSessions: "אין משחקים קרובים",
    noUpcomingSessionsDesc: "לוח הזמנים שלך פנוי! מצא שחקן כדי לקבוע משחק חדש.",
    playingWith: "משחק עם {player}",
    joinGame: "הצטרף למשחק",
    viewDetails: "צפה בפרטים",
    cancleGame: "בטל משחק",
    onlineNow: "מחוברים כעת",
    noFriendsOnline: "אין חברים מחוברים כעת.",
    quickActions: "פעולות מהירות",
    setYourSchedule: "הגדר את לוח הזמנים",
    comfortSettings: "הגדרות נוחות",
    pendingGameRequests: "בקשות משחק ממתינות",
    recived: "התקבל",
    send: "שלח",
    
    // Cancel Session Dialog
    cancelSession: {
      title: "שלח הודעת ביטול",
      description: "הודע לשחקנים על ביטול המשחק בתאריך {date} בשעה {time}.",
      messagePrompt: "עבור {participants} שרוצים לשחק {game}, אנא ספק/י סיבה לביטול:",
      placeholder: "הקלד/י את הודעת הביטול שלך כאן..."
    },
    unexpectedLinkFormat: "פורמט קישור לא צפוי: {data}",
    unexpectedMeetingError: "שגיאה לא צפויה בקישור למפגש: {data}",
    userNotInGuild: "{name} לא נמצא בגילדת TovPlay",
    userNotInGuildDesc: "תצטרכו למצוא אותם ידנית ב-Discord",
    discordBotError: "בוט ה-Discord שלנו לא יכול לגשת למידע על הגילדה",

    // Find Players
    findYourTeammate: "מצא את שותפך הבא למשחק",
    findPlayersSubtitle: "גלה שחקנים בעלי תחומי עניין דומים על בסיס המשחקים שאתה אוהב ומתי אתה פנוי לשחק.",
    findPlayersByGame: "מצא שחקנים לפי משחק",
    noPlayersFound: "לא נמצאו שחקנים זמינים",
    noPlayersFoundDesc: "לא נמצאו שחקני {game} עם זמינות תואמת. נסה לבדוק משחקים אחרים.",
    onlineNowDesc: "שחקנים שמחוברים כרגע וחולקים את תחומי העניין שלך במשחקים.",
    playersWithMatchingAvailability: "שחקני {game} עם זמינות תואמת",
    searchingForPlayers: "מחפש שחקנים...",
    noAvailableSlots: "אין משבצות זמינות",
    offline: "לא מחובר",
    noGamesSelected: "לא נבחרו משחקים",
    noLanguagesSelected: "לא נבחרו שפות",
    sharedLanguages: "שפות משותפות",
    showLess: "הראה פחות",
    moreCount: "+{count} נוספים",
    requestSent: "הבקשה נשלחה",
    requestToPlay: "בקשה לשחק",
    requestSentTitle: "הבקשה נשלחה!",
    requestSentBody: "בקשת המשחק נשלחה אל {username}.",
    close: "סגור",
    requestToPlayTitle: "בקשה לשחק",
    gameLabel: "משחק",
    selectTimeSlots: "בחר משבצות זמן (ניתן לבחור מספר במידת האפשר)",
    checkingAvailability: "בודק זמינות...",
    noTimeSlotsFound: "לא נמצאו משבצות זמן זמינות.",
    requestSentTag: "הבקשה נשלחה",
    timeSlotsSelected: "{count} משבצות זמן נבחרו",
    yourMessage: "ההודעה שלך",
    required: "(חובה)",
    writeFriendlyMessage: "כתוב הודעה ידידותית...",
    characters: "תווים",
    sending: "שולח...",
    sendRequest: "שלח בקשה",
    cancelAction: "ביטול",
    
    // PlayerCard
    noAvailableSlots: "אין זמנים פנויים",
    offline: "לא מחובר",
    noGamesSelected: "לא נבחרו משחקים",
    noLanguagesSelected: "לא נבחרו שפות",
    sharedLanguages: "שפות משותפות",
    requestSent: "בקשה נשלחה",
    requestToPlay: "בקשה למשחק",
    showLess: "הצג פחות",
    moreCount: "+{count} נוספים",

    // Notifications
    notificationsTitle: "התראות",
    notificationsEmpty: "אין התראות עדיין.",
    disconnectTitle: "חיבור ההתראות בזמן אמת התנתק",
    disconnectDescription: "מנסה להתחבר מחדש...",
    dismiss: "סגור",
    cancellationReason: "סיבת ביטול: {reason}",
    markAllAsRead: "סמן הכל כנקרא",
    marking: "מסמן...",

    // Game Requests
    incomingRequestTitle: "{sender} רוצה לשחק איתך!",
    youAskedToPlay: "ביקשת מ-{recipient} לשחק איתך!",
    decline: "דחה",
    accept: "קבל",
    cancelGameRequest: "בטל בקשת משחק",
    
    // GameRequestSentCard
    gameRequestSentCard: {
      youAsked: "ביקשת מ-{username} לשחק",
      cancelRequest: "בטל בקשה"
    },

    // My Profile
    languages: "שפות",
    communication: "תקשורת",
    opennessToNewUsers: "פתיחות למשתמשים חדשים",
    favoriteGames: "משחקים אהובים",
    friendsCount: "חברים",
    gamesCount: "משחקים",
    sessionsCount: "מפגשים",

    // Settings
    comfortAndAccessibility: "הגדרות נוחות ונגישות",
    comfortAndAccessibilityDesc: "התאם אישית את החוויה שלך כך שתתאים לצרכים ולהעדפותיך. כל ההגדרות נועדו לשפר את הנוחות שלך.",
    visualTheme: "ערכת נושא חזותית",
    chooseTheme: "בחר את ערכת הנושא המועדפת עליך",
    lightTheme: "ערכה בהירה",
    darkTheme: "ערכה כהה",
    accessibility: "נגישות",
    reduceMotion: "הפחת תנועה",
    reduceMotionDesc: "צמצם אנימציות ומעברים לחוויה רגועה יותר",
    fontSize: "גודל גופן",
    notifications: "התראות",
    appLanguage: "שפת האפליקציה",
    chooseLanguage: "בחר את השפה המועדפת עליך"
  }
};
