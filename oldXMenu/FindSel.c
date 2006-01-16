#include "copyright.h"

/* Copyright    Massachusetts Institute of Technology    1985	*/
/* Copyright (C) 2002, 2003, 2004, 2005 Free Software Foundation, Inc.  */

/*
 * XMenu:	MIT Project Athena, X Window system menu package
 *
 *	XMenuFindSelection - Find the first selection in a pane who's
 *			     label matches a particular string.
 *
 *	Author:		Tony Della Fera, DEC
 *			January 22, 1986
 *
 */

#include "XMenuInt.h"

int
XMenuFindSelection(menu, p_num, label)
    register XMenu *menu;
    int p_num;
    register char *label;
{
    register XMPane *p_ptr;
    register XMSelect *s_ptr;
    register int i = 0;

    /*
     * Check for NULL pointers!
     */
    if (label == NULL) {
	_XMErrorCode = XME_ARG_BOUNDS;
	return(XM_FAILURE);
    }

    /*
     * Find the right pane.
     */
    p_ptr = _XMGetPanePtr(menu, p_num);
    if (p_ptr == NULL) return(XM_FAILURE);

    /*
     * Find the right selection.
     */
    for (
	s_ptr = p_ptr->s_list->next;
	s_ptr != p_ptr->s_list;
	s_ptr = s_ptr->next
    ){
	if (s_ptr->label_length == 0) {
	    if (*label == '\0') {
		_XMErrorCode = XME_NO_ERROR;
		return (i);
	    }
	}
	else {
	    if (strncmp (label, s_ptr->label, s_ptr->label_length) == 0) {
		_XMErrorCode = XME_NO_ERROR;
		return (i);
	    }
	}
	i++;
    }

    /*
     * If we get here then we have not found
     * a match.
     */
    _XMErrorCode = XME_S_NOT_FOUND;
    return (XM_FAILURE);
}

/* arch-tag: 564a4a95-9ab0-4580-b05f-6970c4b25dd4
   (do not change this comment) */
