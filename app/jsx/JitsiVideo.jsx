import React, { Component } from 'react'

export default class JitsiVideo extends Component {
    constructor(props) {
        super(props)
        this.state = {
            hasLoaded: false
        }
        this.toolbarButtons = [
            'microphone', 'camera', 'closedcaptions', 'desktop', 'fullscreen',
            'fodeviceselection', 'profile', 'chat', 'recording',
            'livestreaming', 'etherpad', 'sharedvideo', 'settings', 'raisehand',
            'videoquality', 'filmstrip', 'invite', 'feedback', 'stats', 'shortcuts',
            'tileview', 'videobackgroundblur', 'download', 'help', 'mute-everyone',
            'e2ee'
        ]
    }

    componentDidMount() {
        this.connect()
    }

    componentWillUnmount() {
        if (this.api) {
            this.api.dispose()
        }
    }

    connect() {
        try {
            // const domain = 'jitsi.gbre.org'
            const domain = 'meet.jit.si'
            const options = {
                roomName: this.props.jitsiData.roomName,
                height: this.props.jitsiData.height || 500,
                parentNode: document.getElementById('jitsi-container'),
                interfaceConfigOverwrite: {
                    // filmStripOnly: true,
                    SHOW_JITSI_WATERMARK: false,
                    DEFAULT_REMOTE_DISPLAY_NAME: 'Fellow Clarendonite',
                    SHOW_WATERMARK_FOR_GUESTS: false,
                    TOOLBAR_BUTTONS: this.toolbarButtons,
                    
                },
                configOverwrite: {
                    disableSimulcast: false
                }
            }
            this.api = new window.JitsiMeetExternalAPI(domain, options)
            this.api.addEventListener('videoConferenceJoined', () => {
                this.api.executeCommand('displayName', this.props.jitsiData.displayName)
                // this.api.executeCommand('avatarUrl', this.props.jitsiData.avatar)
            })
        } catch (err) {
            console.log('failed:', err)
        }
    }

    render() {
        // TODO it feels a bit weird having to reconnect on each render. Will this slow
        // things down?
        if (this.api) {
            this.api.dispose()
            this.connect()
        }
        return (
            <div className="jitsi-video">
                <div id="jitsi-placeholder">
                    Loading video...
                </div>
                <div id="jitsi-container"></div>
            </div>
        )
    }
}
