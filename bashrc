#!/bin/sh

. /etc/profile

PS1="run_woof\\$ "

cd /root/share

# CHECK_FOR_UPDATES and MERGE_UPDATES are defined in run_woof.conf
[ -e run_woof/run_woof.conf ] && . run_woof/run_woof.conf

if [ ! -d woof-CE ]; then

	echo
	echo "Do you want to download woof-CE?"
	echo -n "(y/n)"
	read YESNO
	if [ "$YESNO" = 'y' -o "$YESNO" = 'Y' ]; then
		DOWNLOAD='yes'
		echo
		echo "If you have a fork on GitHub of the woof-CE repo that you want to download,"
		echo "enter your GitHub username, otherwise leave blank to download the main"
		echo "puppylinux-woof-CE/woof-CE repo"
		echo
		echo -n "username: "
		read USERNAME
	fi

	if [ "$DOWNLOAD" = 'yes' ]; then
		if [ "$USERNAME" = '' ]; then
			GIT_SSL_NO_VERIFY=true git clone https://github.com/puppylinux-woof-CE/woof-CE.git
		else
			GIT_SSL_NO_VERIFY=true git clone https://github.com/"$USERNAME"/woof-CE.git

			cd woof-CE

			git remote add upstream https://github.com/puppylinux-woof-CE/woof-CE.git
			GIT_SSL_NO_VERIFY=true git fetch -v upstream

			GIT_STATUS="`git status`"
			ON_BRANCH="$(expr match "$(echo "$GIT_STATUS" | grep 'On branch')" 'On branch \(.*\)')"
			if [ "`git branch -r | grep "upstream/${ON_BRANCH}"`" != '' ]; then
				git branch --set-upstream-to=upstream/${ON_BRANCH}
			fi

			cd ..
		fi
	fi
else

	if [ "$CHECK_FOR_UPDATES" = 'no' ]; then
		YESNO='n'
	elif [ "$CHECK_FOR_UPDATES" = 'yes' ]; then
		YESNO='y'
	else
		echo
		echo "Do you want to check for any updates to woof-CE?"
		echo -n "(y/n)"
		read YESNO
		echo
	fi

	if [ "$YESNO" = 'y' -o "$YESNO" = 'Y' ]; then

		cd woof-CE

		if [ "`git remote | grep 'upstream'`" != '' ]; then
			FETCH_URL="`git remote show -n upstream | grep 'Fetch URL:'`"
			if [ "`echo "$FETCH_URL" | grep 'Fetch URL: http'`" = '' ]; then
				# only http works from inside run_woof
				GIT_SSL_NO_VERIFY=true git fetch -v https://github.com/$(expr match "$FETCH_URL" '.*github.com:\(.*\)') "+refs/heads/*:refs/remotes/upstream/*"
			else
				GIT_SSL_NO_VERIFY=true git fetch -v upstream
			fi
			echo
		fi

		if [ "`git remote | grep 'origin'`" != '' ]; then
			FETCH_URL="`git remote show -n origin | grep 'Fetch URL:'`"
			if [ "`echo "$FETCH_URL" | grep 'Fetch URL: http'`" = '' ]; then
				# only http works from inside run_woof
				GIT_SSL_NO_VERIFY=true git fetch -v https://github.com/$(expr match "$FETCH_URL" '.*github.com:\(.*\)') "+refs/heads/*:refs/remotes/origin/*"
			else
				GIT_SSL_NO_VERIFY=true git fetch -v origin
			fi
			echo
		fi

		GIT_STATUS="`git status`"
#		echo "$GIT_STATUS"

		if [ "`echo $GIT_STATUS | grep 'and can be fast-forwarded'`" != '' ]; then

			if [ "$MERGE_UPDATES" = 'no' ]; then
				YESNO='n'
			elif [ "$MERGE_UPDATES" = 'yes' ]; then
				YESNO='y'
			else
				echo "Do you want to update your local woof-CE repo?"
				echo -n "(y/n)"
				read YESNO
				echo
			fi

			if [ "$YESNO" = 'y' -o "$YESNO" = 'Y' ]; then
				TRACKING_BRANCH="$(expr match "$(echo "$GIT_STATUS" | grep 'Your branch is behind')" "Your branch is behind '\(.*\)'")"
#				echo "$TRACKING_BRANCH"
				if [ "$TRACKING_BRANCH" != '' ]; then
					git merge --ff-only "$TRACKING_BRANCH"
				fi
			fi
		fi

		cd ..
	fi
fi
echo
echo "Type exit and press <Enter> to leave run_woof"
echo
