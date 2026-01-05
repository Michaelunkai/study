import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Loader2 } from "lucide-react";
import { apiService } from "@/api/apiService";

export function CommunityDialog({ isOpen, onClose, discordInviteLink }) {
  const [isChecking, setIsChecking] = useState(false);
  const [joinMessage, setJoinMessage] = useState('');
  const MAX_RETRIES = 3;

  const checkStatus = async (attempt = 1) => {
    try {
      console.log('Checking community status, attempt:', attempt);
      const response = await apiService.checkCommunityStatus();
      console.log('Community status response:', response);
      
      // Check if there's an error in the response
      if (response.error) {
        console.log('Response contains error:', response.error);
        // If user is not connected with Discord, no point in retrying
        if (response.error.includes('not connected with Discord')) {
          setJoinMessage('Please connect your Discord account first.');
          setIsChecking(false);
          return;
        }
        
        if (attempt < MAX_RETRIES) {
          // Retry after a delay
          setJoinMessage(`Having trouble connecting. Retrying... (${attempt}/${MAX_RETRIES})`);
          setTimeout(() => checkStatus(attempt + 1), 2000);
          return;
        }
        throw new Error(response.error);
      }
      
      // Check if user is in community
      const isInCommunity = response.in_community === true || 
                     response.in_community === 'true' || 
                     response.in_community === null; // Add this line
      console.log('isInCommunity:', isInCommunity);
      
    // And update the message to show the actual value for debugging:
    console.log('Community status raw response:', {
      in_community: response.in_community,
      type: typeof response.in_community,
      fullResponse: response
    });

      if (isInCommunity) {
        // If already in community, update the UI and close the dialog
        setJoinMessage('Success! Welcome to the community!');
        
        // Close the dialog after a short delay
        setTimeout(() => {
          onClose();
          // Reload the page to update the UI
          window.location.reload();
        }, 1500);
      } else if (attempt < MAX_RETRIES) {
        // If not in community but have retries left, try again
        setJoinMessage(`Checking your status... (${attempt}/${MAX_RETRIES})`);
        setTimeout(() => checkStatus(attempt + 1), 2000);
      } else {
        // If max retries reached and still not in community
        setJoinMessage('Please complete the Discord join process and try again.');
        setIsChecking(false);
      }
    } catch (error) {
      console.error('Error checking community status (attempt', attempt, '):', error);
      if (attempt < MAX_RETRIES) {
        // Retry on error
        setJoinMessage(`Having trouble connecting. Retrying... (${attempt}/${MAX_RETRIES})`);
        setTimeout(() => checkStatus(attempt + 1), 2000); // 2 second delay
      } else {
        setJoinMessage('Error checking your status. Please try again later.');
        setIsChecking(false);
      }
    }
  };

  const handleJoinCommunity = async () => {
    if (!discordInviteLink) return;
    
    // Show loading state
    setIsChecking(true);
    setJoinMessage('Opening Discord...');
    
    try {
      // First, try to update the community status
      await apiService.setInCommunityTrue();
      console.log('Successfully updated community status');
      
      // Then open Discord in a new tab
      window.open(discordInviteLink, "_blank", "noopener,noreferrer");
      
      // Start checking status after a short delay to give Discord time to load
      setTimeout(() => {
        setJoinMessage('Please wait while we check your community status...');
        // Start checking status with retries
        checkStatus(1);
      }, 2000);
    } catch (error) {
      console.error('Error updating community status:', error);
      // Still open Discord even if there was an error updating status
      window.open(discordInviteLink, "_blank", "noopener,noreferrer");
      setJoinMessage('Please join the Discord server and we\'ll verify your membership.');
      setIsChecking(false);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Join Our Community</DialogTitle>
          <DialogDescription className="space-y-2">
            <p>You need to join our Discord community to access all features.</p>
            {joinMessage && (
              <p className="text-sm text-foreground/80 bg-muted/50 p-2 rounded-md">
                {joinMessage}
              </p>
            )}
            <p className="text-sm text-muted-foreground">
              Already joined? The page will refresh automatically once we detect your membership.
            </p>
          </DialogDescription>
        </DialogHeader>
        <DialogFooter className="gap-3">
          <Button 
            onClick={onClose} 
            variant="outline"
            className="border-teal-500 text-teal-600 hover:bg-teal-50 hover:text-teal-700"
          >
            Maybe Later
          </Button>
          <Button 
            onClick={handleJoinCommunity}
            className="bg-teal-600 hover:bg-teal-700 text-white"
            disabled={isChecking}
          >
            {isChecking ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Verifying...
              </>
            ) : (
              'Join Discord Community'
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
