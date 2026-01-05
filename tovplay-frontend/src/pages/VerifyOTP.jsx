import { useEffect } from "react";
import axios from '@/lib/axios-config';
import { useState } from "react";
import { useParams } from "react-router";
import { useNavigate } from 'react-router-dom';
import { createPageUrl } from "@/utils/index.ts";


const verifyOTP = () => {

//     const { email, otp } = useParams();
    const [email, setEmail] = useState(useParams().email || "");
    const [otp, setOtp] = useState(useParams().otp || "");
    const navigate = useNavigate();


    const getParams = () => {
        // setEmail(email);
        // setOtp(otp);
    }

    const verifyEmail = async () => {
        try {
            const response = await axios.get(`/api/auth/verify-otp?email=${email}&otp_code=${otp}`);
            debugger;

            // redirect to login page after successful verification
            if (response.status === 200 || response.status === 201) {
                setTimeout(() => {
                    navigate(createPageUrl('SignIn'));
                }, 10000);
            }

        } catch (error) {
            console.error("Error verifying email:", error);
        }
    }

    useEffect(() => {
        // getParams();
        verifyEmail();
    }, []);


    return (
        <>
            <div>Your mail {email} has been verified. Redirecting to login Page ...</div>
        </>
    );


}

export default verifyOTP;